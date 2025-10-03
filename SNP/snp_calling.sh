#Wuhan strain will be used as reference genome. NC_045512.2
/usr/local/kSNP3/MakeKSNP3infile ../genome/single_genome ksnp_in_list A
tcsh /usr/local/kSNP3/kSNP3 -in ksnp_in_list -outdir run1 -k 13 -vcf -CPU 8 > run1_log 2>&1                                                      