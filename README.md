## aFC Pipeline:
The aFC script makes a number of assumptions about the input data.  
Refer to https://github.com/secastel/aFC  

Included in this repo, are two workflows, one for running the aFC pipeline, and one for preprocessing our current bed and vcfs.  
The bed preprocessing is converting it into a bgzip for mat.  
The VCF preprocessing is adding an id that matches the format expected in the QTL output file.  

In addition, the QTL file should contain the fields, pid, sid, sid_chr, and sid_pos see secastel/aFC for more details.  
