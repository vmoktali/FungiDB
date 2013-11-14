# User provides this information
RUN_NAME ?= test
FASTA ?= botrytis_cinerea__b05.10__1_proteins.fasta
BATCH_SIZE ?= 100

# Directories
RUN_DIR = ${CURDIR}/runs/$(RUN_NAME)
FASTA_DIR = $(RUN_DIR)/fasta
BLAST_DIR = $(RUN_DIR)/blast
BLASTXML_DIR = $(RUN_DIR)/blastxml
INTERPRO_DIR = $(RUN_DIR)/interpro
GO_DIR = $(RUN_DIR)/go
GO_BACKUP_DIR = $(RUN_DIR)/go_backup
YML_DIR = $(RUN_DIR)/yml
RESULTS_DIR = $(RUN_DIR)/results
FINAL_DIR = $(RUN_DIR)/final
 
# Constants
AHRD_JAR := /rhome/vmoktali/tools/AHRD/dist/ahrd.jar
B2GO_DIR := /rhome/vmoktali/tools/bl2go/b2g4pipe
B2GO_PROP := /rhome/vmoktali/tools/b2g4pipe/b2gPipe.properties
BATCH_YML := $(RUN_DIR)/batch_input.yml
BATCH_SH := $(RUN_DIR)/batch_input.sh
BLACKLIST_FILE := /rhome/vmoktali/tools/AHRD/test/resources/blacklist_descline.txt
FILTER_DIR := /rhome/vmoktali/tools/AHRD/filter
TOKEN_BLACKLIST := /rhome/vmoktali/tools/AHRD/test/resources/blacklist_token.txt
INTERPRO_DATABASE := /rhome/vmoktali/tools/AHRD/Cneoformans/interpro.42.0.xml
# Need to create a filter file for all the blast dbs targeted
swissprot_target := /srv/projects/db/NCBI/swissprot/swissprot
sgd_target := /rhome/vmoktali/tools/AHRD/SGD/yeast.fasta
nr_target := /srv/projects/db/NCBI/current/nr

all: fasta blast go interpro
	${MAKE} yml ahrd

fasta: $(FASTA_DIR)

blast: $(BLAST_DIR)/swissprot $(BLAST_DIR)/sgd

blastxml: $(BLASTXML_DIR)

go: $(GO_BACKUP_DIR)

interpro: $(INTERPRO_DIR)

yml: $(YML_DIR)

clean_all:
	rm -rf $(RUN_DIR)
clean_fasta:
	rm -rf $(FASTA_DIR)
clean_blast:
	rm -rf $(BLAST_DIR)
clean_go:
	rm -rf $(GO_DIR)
clean_interpro:
	rm -rf $(INTERPRO_DIR)
clean_yml:
	rm -rf $(BATCH_YML) $(YML_DIR)


$(FASTA_DIR):
	mkdir -p $@
	./split_fasta.py -i $(FASTA) -n $(BATCH_SIZE) -o $@

$(BLAST_DIR)/%: $(FASTA_DIR)
	mkdir -p $@
	cd $< && parallel 'blastall -p blastp -i {} -d $($*_target) -e 1e-3 -o $@/{.}.pairwise' ::: *.fasta

$(INTERPRO_DIR): $(FASTA_DIR)
	mkdir -p $@
	cd $< && parallel 'interproscan.sh -t p -pathways -goterms -i {} -T /dev/shm -b $@/' ::: *.fasta

$(BLASTXML_DIR): $(FASTA_DIR)
	mkdir -p $@
	cd $< && parallel 'blastp -query {} -db $(nr_target) -outfmt 5 -evalue 1e-3 -max_target_seqs 20 -out $@/{.}.xml' ::: *.fasta

$(GO_BACKUP_DIR): $(BLASTXML_DIR)
	mkdir -p $@
	cd $< && parallel 'java -Xmx500m -cp $(B2GO_DIR)/*:$(B2GO_DIR)/ext/*: es.blast2go.prog.B2GAnnotPipe -prop $(B2GO_PROP) -in {} -annot -out $@/{.}.csv' ::: *.xml

$(BATCH_YML):
	@echo 'shell_script: $(BATCH_SH)' > $@
	@echo 'ahrd_call: "java -Xmx2048m -jar $(AHRD_JAR) #batch#"' >> $@
	@echo 'proteins_dir: $(FASTA_DIR)' >> $@
	@echo 'batch_ymls_dir: $(YML_DIR)' >> $@
	@echo 'token_score_bit_score_weight: 0.5' >> $@
	@echo 'token_score_database_score_weight: 0.3' >> $@
	@echo 'token_score_overlap_score_weight: 0.2' >> $@
	@echo 'description_score_relative_description_frequency_weight: 0.6' >> $@
	@echo 'blast_dbs:' >> $@
	@for d in $(BLAST_DIR)/*; do \
		echo " $$(basename $$d):" >> $@; \
		echo "   dir: $$d" >> $@; \
		echo "   weight: 100" >> $@; \
		echo "   blacklist: $(BLACKLIST_FILE)" >> $@; \
		echo "   filter: $(FILTER_DIR)/$$(basename $$d)/filter_descline.txt" >> $@; \
		echo "   token_blacklist: $(TOKEN_BLACKLIST)" >> $@; \
		echo "   description_score_bit_score_weight: 0.7" >> $@; \
	done
	@if [ -d $(INTERPRO_DIR) ]; then \
		echo 'interpro_results_dir: $(INTERPRO_DIR)' >> $@; \
		echo 'interpro_database: $(INTERPRO_DATABASE)' >> $@; \
	fi
	@if [ -d $(GO_DIR) ]; then \
		echo 'gene_ontology_results_dir: $(GO_DIR)' >> $@; \
	fi
	@echo 'output_dir: $(RESULTS_DIR)' >> $@

$(YML_DIR): $(BATCH_YML)
	mkdir -p $@
	java -cp $(AHRD_JAR) ahrd.controller.Batcher $<

ahrd: $(YML_DIR)
	java -Xmx2g -jar $(AHRD_JAR) $</*.yml
	cat $(RESULTS_DIR)/*.csv | $(FINAL_DIR)/final.csv
	sed '/^#.*$/d' $(FINAL_DIR)/final.csv > $(FINAL_DIR)/final_1.csv
	sed '/^Protein.*$/d' $(FINAL_DIR)/final_1.csv > $(FINAL_DIR)/final_2.csv
	sed '/^$/d' $(FINAL_DIR)/final_2.csv > $(FINAL_DIR)/final_3.csv
	cut -f1,1,4 $(FINAL_DIR)/final_3.csv > $(FINAL_DIR)/final_filter.csv
	sort -k1 $(FINAL_DIR)/final_filter.csv > $(FINAL_DIR)/products.txt
	cd $(FINAL_DIR) && rm -rf final_1.csv final_2.csv final_3.csv final_filter.csv

	

.PHONY: all fasta blast go interpro yml clean_all clean_fasta clean_blast clean_go clean_interpro clean_yml ahrd
