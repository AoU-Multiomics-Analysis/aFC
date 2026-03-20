## aFC Pipeline:
The aFC script makes a number of assumptions about the input data.  
Refer to https://github.com/secastel/aFC  

Included in this repo, are two workflows, one for running the aFC pipeline, and one for preprocessing our current bed and vcfs.  
The bed preprocessing is converting it into a bgzip for mat.  
The VCF preprocessing is adding an id that matches the format expected in the QTL output file.  

In addition, the QTL file should contain the fields, pid, sid, sid_chr, and sid_pos see secastel/aFC for more details.  
Not included in here, is a pipeline to preprocess the QTL file, which was processed outside of the pipeline with python as it was a relatively small file.  

In general, run the preprocess step on the existing VCF, and BED is they do not meet the requirements of the aFC script, and then run the aFC script.
