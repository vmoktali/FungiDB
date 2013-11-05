#!/usr/bin/env python
from gff_parser import GFFParser, Feature


"""Takes input GFF3 file name

returns file with shared exons separated into individual lines

"""

def splice_separator(infile, outfile):
    
    stream = open(infile)
    parser = GFFParser('gff3')
    
    with open('outfile.gff3', 'w') as outfile:
        for feat in parser.parse_features(stream, commentfile=outfile):
            if feat.soterm in ('exon', 'CDS'):
                parents = feat.attr['Parent'].split(',')
                ID = feat.attr['ID'].split(':')
                for p in parents:
                    feat2 = Feature.from_feature(feat)
                    feat2.attr['ID'] = ":".join([p] + ID[1:])
                    feat2.attr['Parent'] = p
                    print >> outfile, parser.join_feature(feat2)
            else:
                print >> outfile, parser.join_feature(feat) 