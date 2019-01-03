#!/usr/bin/env python
"""Replace named Docker secrets within a file with their values"""
import sys
import os
import re
import argparse


def replace_secrets(target_file, secrets_dir="/run/secrets"):
    """
    Replace named Docker secrets within `target_file`.

    Replaces the named Docker secrets within `target_file`, using the 
    secrets stored in `secrets_dir` and returns the result. Secret 
    names within `target_file` should be declared within brakets. As 
    an example, `{MY_SECRET}` will be replaced with the contents of 
    the file `secrets_dir/my_secret`.

    :param str target_file: File to search and replace Docker secrets 
       with their values.
    :param str secrets_dir: Location of in-memory filesystem that the 
       Docker secrets have been mounted into.
    :raises TypeError: if target_file is not a readable file or 
       secrets_dir is not a readable directory.
    """

    # Check to make sure secrets_dir is a directory and can be read from
    if not os.path.exists(secrets_dir):
        raise TypeError(
            "Given secrets directory does not exist".format(
                secrets_dir
            )
        )
    elif not os.path.isdir(secrets_dir):
        raise TypeError(
            "Given secrets directory is not a directory".format(
                secrets_dir
            )
        ) 
    elif not os.access(secrets_dir, os.R_OK):
        raise TypeError(
            "Given secrets directory is not readable".format(
                secrets_dir
            )
        ) 
    # Check to make sure target_file is a file and can be read from
    elif not os.path.exists(target_file):
        raise TypeError(
            "Given target file does not exist".format(
                target_file
            )
        )
    elif not os.path.isfile(target_file):
        raise TypeError(
            "Given target file is not a file".format(
                target_file
            )
        )
    elif not os.access(target_file, os.R_OK):
        raise TypeError(
            "Given target file is not readable".format(
                target_file
            )
        )

    # Get a list of all secrets found in secrets_dir, formatted as they
    # should be in the target file
    known_secrets = os.listdir(secrets_dir)

    # Read the file and look for secrets found inside of secrets_dir
    with open(target_file, 'r') as tf:
        tf_contents = tf.read()
        for known_secret in known_secrets:
            # secrets_dir/known_secret -> {KNOWN_SECRET}
            ks_dec = "{{{}}}".format(known_secret.upper())

            if ks_dec in tf_contents:
                # Read in the secret and replace it
                ks_path = os.path.join(secrets_dir, known_secret)
                with open(ks_path, 'r') as ks:
                    # Strings are immutable
                    tf_contents = tf_contents.replace(
                        ks_dec, ks.read().strip()
                    )

    # If we still have unfilled secrets in tf_contents, raise an error
    secrets_left = re.findall("\{[A-Z]+\}", tf_contents)
    if len(secrets_left) > 0:
        raise ValueError(
            "Unknown secrets found in given target file: {}".format(
                ', '.join(secrets_left)
            )
        )
 
    return tf_contents


def main():
    """
    Load and parse arguments, passing them to `replace_secrets`.

    Will print out the result from `replace_secrets` so it can be piped
    into a different command.

    :return: None
    """

    parser = argparse.ArgumentParser(
        description='Replace named Docker secrets within a file with their values.'
    )
    parser.add_argument('target_file', help='File containing secrets to replace.')
    parser.add_argument(
        '--secrets-dir', default='/run/secrets', 
        help='Directory containing secrets files. Defaults to /run/secrets.'
    ) 

    args = parser.parse_args()
    result = replace_secrets(
        args.target_file, 
        secrets_dir=args.secrets_dir, 
    )

    print result 

     
if __name__ == '__main__':
    main()

