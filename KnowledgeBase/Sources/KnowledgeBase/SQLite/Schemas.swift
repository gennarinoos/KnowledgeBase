//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/25/21.
//

import Foundation

// KV Schema

let kKBTypedKeyValuePairsDbSchema = """
CREATE TABLE "link" (
id TEXT PRIMARY KEY NOT NULL,
subject TEXT NOT NULL,
predicate TEXT NOT NULL,
object TEXT NOT NULL,
count INTEGER DEFAULT 1,
attributes TEXT
);
CREATE TABLE "intval"(
k TEXT PRIMARY KEY NOT NULL,
v INTEGER
);
CREATE TABLE "realval"(
k TEXT PRIMARY KEY NOT NULL,
v REAL
);
CREATE TABLE "textval"(
k TEXT PRIMARY KEY NOT NULL,
v TEXT
);
CREATE TABLE "blobval"(
k TEXT PRIMARY KEY NOT NULL,
v BLOB
);
PRAGMA case_sensitive_like = true
"""
