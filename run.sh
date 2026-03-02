#!/usr/bin/env bash

iverilog -v testbench/sisc_tb_p1.v -I lib/* src/*
