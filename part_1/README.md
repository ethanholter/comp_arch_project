**docs**: project instruction pdfs

**lib**: given files, not allowed to change these

**src**: project files requiring implementation

**testbench**: contains sisc_tb.v test bench file

to run:
```bash
iverilog -v testbench/sisc_tb_p1.v -I lib/* src/*
```
