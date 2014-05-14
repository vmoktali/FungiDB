'''
Program that identifies the mutant amino acid (at position 238) in the human ADA gene.

'''
#Import packages
from Bio.Seq import Seq
from Bio import SeqIO
from Bio.Alphabet import generic_dna
import re

#open fasta record for processing
handle = open("ada.fasta", "rU")

#use SeqIO to extract the sequence
for record in SeqIO.parse(handle, "fasta"):
    coding_dna = record.seq
    coding_dna = str(coding_dna)

#find index of start codon
start_index = coding_dna.index("ATG")+1

#get start index of the first nucleotide of codon to be mutated
mutant_codon_start = start_index + 237

#get the codon triplet to be mutated
original_codon = coding_dna[mutant_codon_start-1:mutant_codon_start+2]

#translate original codon
original_aa = Seq(original_codon, generic_dna)
original_aa = original_aa.translate()

#mutate the original codon by replacing middle A->G
mutant_codon = list(original_codon)
mutant_codon[1] = "G"
mutant_codon = "".join(mutant_codon)

#translate mutant codon
mutant_aa = Seq(mutant_codon, generic_dna)
mutant_aa = mutant_aa.translate()

#print output
print "Original codon:"+original_codon
print "Mutant codon:"+mutant_codon
print "Original Amino Acid:"+original_aa
print "Mutant Amino Acid:"+mutant_aa







