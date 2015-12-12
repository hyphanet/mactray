#!/bin/env/python

from __future__ import print_function

import argparse
import os.path
import subprocess
import hashlib


DATA_SECTIONS = ["__data", "__la_symbol_ptr", "__nl_symbol_ptr", "__dyld", "__const", "__mod_init_func", "__mod_term_func", "__bss", "__common"]
TEXT_SECTIONS = ["__text", "__cstring", "__picsymbol_stub", "__symbol_stub", "__const", "__literal4", "__literal8"]

DATA_SEGMENT = "__DATA"
TEXT_SEGMENT = "__TEXT"

def check_sections(segment_name, sections, path):
    section_shasums = {}
    for section_name in sections:
        output = subprocess.check_output(["otool", "-s", segment_name, section_name, path])
        output = ''.join(output.splitlines(True)[1:])
        section_shasums[section_name] = hashlib.sha256(output).hexdigest()
    return section_shasums

def compare_section_shasums(segment_name, first, second):
    failure = False
    for key in first:
        if first[key] != second[key]:
            failure = True
            print("WARNING: %s,%s DOES NOT MATCH!!!" % (segment_name, key))
        else:
            print("OK: %s,%s" % (segment_name, key))
    return failure

def check_path_exists(path):
    if not os.path.exists(path):
        print("File %s not found" % path)
        exit(1)

def verify_files(first, second):
    check_path_exists(first)
    check_path_exists(second)
    
    first_data_sections_sha = check_sections(segment_name=DATA_SEGMENT, sections=DATA_SECTIONS, path=first_path)
    second_data_sections_sha = check_sections(segment_name=DATA_SEGMENT, sections=DATA_SECTIONS, path=second_path)

    first_text_sections_sha = check_sections(segment_name=TEXT_SEGMENT, sections=TEXT_SECTIONS, path=first_path)
    second_text_sections_sha = check_sections(segment_name=TEXT_SEGMENT, sections=TEXT_SECTIONS, path=second_path)

    
    data_mismatch = compare_section_shasums(segment_name=DATA_SEGMENT, first=first_data_sections_sha, second=second_data_sections_sha)
    text_mismatch = compare_section_shasums(segment_name=TEXT_SEGMENT, first=first_text_sections_sha, second=second_text_sections_sha)
    
    if data_mismatch or text_mismatch:
        print("WARNING: FILES ARE NOT IDENTICAL!!!")
        exit(1)
    print("File verification succeeded")
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("first", help="first file to compare")
    parser.add_argument("second", help="second file to compare")
    args = parser.parse_args()

    first_path = args.first
    second_path = args.second
    verify_files(first_path, second_path)
    


	
