#!/usr/bin/perl -w

# use this script to create a fasta file of uniq sequences 
# and one that contains the ids as descritpion
#To add: a distribution of the number of sequences

use strict;
use Bio::SeqIO;
use Getopt::Long; 


my ($infile,$first);
&GetOptions(
	    'in:s'      => \$infile,#fasta file
	    'f'         => \$first, # use this argument if you want the sequence to be 
	    # labelled according to first occurence of a sequence, sequences need to be labelled with sampling day D\d+
           );

print "$infile\n";
if ($infile=~/(.+)\.(fa|fna|fasta|fsa)/){ 
  my $filename=$1;
  my $in = Bio::SeqIO->new(-file=>"$infile", -format=>"fasta");

   my %matching_hash = ();
   my %final_hash = ();
   my $outfilename=$filename.".uniq.fa";
   my $outfileids=$filename."uniq.ids.fa";

   my $out = Bio::SeqIO->new(-file => ">$outfilename" , '-format' => 'fasta');
   my $outid = Bio::SeqIO->new(-file => ">$outfileids" , '-format' => 'fasta');

   while (my $obj = $in->next_seq) { 
     if ($final_hash{uc($obj->seq)}){
      my $id=$obj->display_id." ".$final_hash{uc($obj->seq)};
      $final_hash{uc($obj->seq)} = $id;
      $matching_hash{uc($obj->seq)}++;
     }else{
      my $id=$obj->display_id;
      $final_hash{uc($obj->seq)} = $id;
      $matching_hash{uc($obj->seq)}++;      
     }
    } 
   foreach my $uniqseq (keys %final_hash){
     if ($uniqseq){
      # print "$uniqseq $final_hash{$uniqseq}\n";
       my $desc=$final_hash{$uniqseq};
       my $new_id;
       my $date=1000000000000000;
       if ($first){
         my @ids = split (/\s+/,$desc);
         foreach my $ids (@ids){
           my $newdate; 
           if ($ids=~/D(\d+)S\d+$/){
             $newdate=$1;
           }else{
             $newdate=1000000000000000;
             #print "New date $newdate\n";
           }if ($newdate<$date){
             $date=$newdate;
             $new_id=$ids."_$matching_hash{$uniqseq}";
             
           }
         }
       }else{
         $new_id=$1."_$matching_hash{$uniqseq}" if $desc=~/^(\S+)/;
       }
       print ">$new_id< and $desc\n";
       if ($new_id){
         my $newseq = Bio::Seq->new(-seq => "$uniqseq",  
                         -desc => "$final_hash{$uniqseq}",
                         -display_id => $new_id);
                         # -desc => "$final_hash{$uniqseq}",
         $outid->write_seq($newseq);
         my $seq = Bio::Seq->new(-seq => "$uniqseq",  
                         
                          -display_id => $new_id);
                          # -desc => "$final_hash{$uniqseq}",
         $out->write_seq($seq);

       }else{
         print "ERROR: no ID for $final_hash{$uniqseq}\n";
       }   
     }
   }
   my %freq;
   foreach my $seqstr(keys %matching_hash){
     $freq{$matching_hash{$seqstr}}++;
   }
   print "x sequences with y copies\n";
   foreach my $seqnb (sort keys %freq){
     print "$freq{$seqnb}\t$seqnb\t";
     for (my $i=0; $i<$freq{$seqnb}; $i++){
       print "=";
     }
     print "\n";
   }
}else{
  print "The file doesn't seem to be in fasta format (.fa, .fasta or .fna)";
}



