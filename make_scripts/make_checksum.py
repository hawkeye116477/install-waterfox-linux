#!/usr/bin/env python3
# pylint: disable=C0103
"""Create checksum file"""
import os
import sys
import hashlib

pj = os.path.join
pn = os.path.normpath

script_path = os.path.dirname(os.path.realpath(__file__))
main_path = pn(script_path+"/..")
artifacts_path = pj(main_path, "artifacts")

zipFile = sys.argv[1]

checksum_file_path = pj(
    artifacts_path, os.path.basename(zipFile).replace(".zip", ".sha256"))

if os.path.exists(checksum_file_path):
    os.remove(checksum_file_path)

if os.path.exists(zipFile):
    with open(zipFile, 'rb') as file_to_check:
        data = file_to_check.read()
    checksum = hashlib.sha256(data).hexdigest()
    with open(checksum_file_path, "a", encoding='utf-8') as checksum_file:
        checksum_file.write(checksum+" "+os.path.basename(zipFile)+"\n")
