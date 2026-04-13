#!/usr/bin/env bash

iverilog -Wall -i -g2012 testbench/sisc_tb_p1.v -I lib/* src/*
