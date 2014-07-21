# CFF README

Updated: 6/4/2014
Copyright 2014

## DESCRIPTION

The Cluster-Free Filtering package (CFF) is a fast denoiser designed for analyzing multi-sample metagenomic datasets from "tag sequencing" experiments (e.g. 16S). Its purpose is to identify and eliminate sequences generated by substitution errors during PCR or sequencing. The algorithm does not cluster similar sequences together, which allows analyzing moderate-abundance community members with sub-OTU (single-nucleotide) resolution. The intended application is for analyzing subtle compositional differences between broadly similar communities, e.g. a location series of similar microbial habitats or a time series sampling the same habitat.

This version works best with Illumina data. The package will also work with 454 data, but is much slower because it requires sequence alignments. We have not tested CFF on data from other platforms (IonTorrent, etc.); if you have such data and are interested in trying CFF, please contact us (see below).

This README file provides only basic installation/usage information. For a thorough introduction to the cluster-free filtering approach, including the motivation, algorithm, limitations and examples of application, see [1]. For detailed usage information of individual scripts, see built-in documentation.


## THE PIPELINE

The pipeline is an 8-step process. It can be run with a single command (run_CFF_on_FastA.tcsh, run_CFF_on_FastQ.tcsh, or run_CFF_on_454_FastA.tcsh), but each script component is also available.

    1. mergeSeqs.pl     truncates, dereplicates, and renames sequences in samples
    2. neighbors.pl     generates a list of Hamming distance 1 sequences
    3. errorRates.pl    generates a Z-Score histogram (see -h)
    4. errorRates.pl    estimates substitution error rate (see -z)
    5. nZeros.pl        calculates null model abundance (N0) for each sequence
    6. getCandidates.pl filters sequences by N/N0 threshold
    7. getReals.pl      filters chimeric candidates and generates overall abundance table
    8. filterIndels.pl  (optional) identifies sequences differing by indels

Note that when analyzing 454 data, filterIndels.pl must be run first. These scripts assume that each "real" sequence (those we seek to identify), whenever present in the sample, start from the same place in its sequence. In particular, CFF will work with any PCR-amplified tag sequencing dataset (such as 16S), but is NOT applicable to shotgun metagenomics where sequences need to be aligned to match each other.

Briefly, sequences in samples are renamed so that each sequence is assigned the same name whenever it appears (within and across samples). Next, the data is used to estimate substitution error rates. This is done by assuming that for each abundant sequence, most of its Hamming-distance-1 neighbors were in fact generated through PCR/sequencing errors. The estimated error rates are used to calculate, for each sequence, its expected abundance N0 under the substitution-only error model. Sequences whose observed abundance significantly exceeds this predicted null-model abundance are "nominated" as candidate reals. Non-chimeric sequences that received enough "candidate" nominations (across all samples) are retained as real, and a final table is generated listing the abundance of all real sequences as observed across all samples. In this manner even low-abundance sequences are recorded, as long as they could be confidently identified as present above background in a sufficient number of other samples; see [1].

The pipeline is designed to filter for errors that are the result of sequencing or PCR substitutions.  However, an additional pre-/post-filtering step has been provided to identify possible indels. This step is optional as a post-filtering when applied to Illumina data, but is required as a pre-filtering step when applied to 454 data, where indel errors are commonly generated during sequencing.

Helpful definitions:

    Candidate:         A sequence that is suspected to not be the
                       result of a PCR substitution error and may
                       exist in the original biological sample.
    Real sequence:     A candidate sequence that was found in an
                       arbitrary minimum threshold number of
                       samples (and may have been optionally
                       screened for chimerism).
    Fake sequence:     A sequence that is presumed to be the result
                       of a PCR substitution error and is believed
                       to not exist in the original biological
                       sample.
    Indel:             A DNA insertion or deletion.
    Mother sequence:   A theoretical real sequence from which
                       erroneous sequences are derived.  Each
                       sequence in column 1 of the neighbors file
                       is referred to as a mother sequence when
                       comparing it to its neighbors on that row.
    N0 ("N zero"):     The abundance of a sequence that would be
                       expected if it is the result of a PCR
                       substitution error.
    N/N0:              A.k.a. the "abundance/N0" fraction.  This is
                       the abundance of a sequence divided by the
                       expected abundance if the sequence is a fake
                       sequence (i.e. the result of a PCR
                       substitution error).
    Neighbor sequence: A sequence that differs by 1 substitution
                       from a mother sequence.  Also referred to as
                       "1st neighbor" or "hamming distance 1
                       neighbor".
    Reverse Spillover: An error that reverses a previous error to
                       be correct by chance, or an error that
                       causes a real sequence to turn into a
                       different real sequence.
    Z Score:           During the estimation of the error rates, a
                       Z Score is calculated for each neighbor.  It
                       is computed as:

                       z = (An - Amu) / Astddev

                       where An is the abundance of a particular
                       neighbor, Amu is the average neighbor
                       abundance, and Astddev is the standard
                       deviation of neighbor abundance.  It is then
                       used with a supplied threshold to filter out
                       potential real sequences from the estimation
                       of the error background.

Note, each script is designed to handle multiple input files.  If you supply 1 of one type of file and 10 of another type of file, the same single file will be used for processing each of the other 10 files.  E.g.:

    nZeros.pl -i "*.fna" -n all_neighbors.nbrs -r my_error_rates.err -o .n0

nZeros.pl will use the same neighbors and error rates files when processing each sequence file.

## LICENSE

Read LICENSE

## DOCUMENTATION

Other than this README and the LICENSE, documentation is in the scripts themselves and can be viewed by supplying --help (or --help --extended).  Usage can be viewed by simply running the scripts without any parameters.

## DOWNLOAD

https://github.com/hepcat72/CFF/archive/master.zip

## INSTALL

Dependencies:

    muscle - alignment tool required by filterIndels.pl
    http://www.drive5.com/muscle/downloads.htm

    uchime (i.e. usearch) - chimera tool required by getReals.pl
    http://drive5.com/uchime/uchime_download.html

Install the above dependencies and make sure muscle is in your PATH, then install CFF.  You may install muscle afterwards, but you will see an error.

In a terminal window, cd into the CFF directory and run the following commands:

    perl Makefile.PL
    make
    make install

Perl Module Dependencies:

    Getopt::Long       (version 2.38)   #REQUIRED
    File::Glob         (version 1.17)   #REQUIRED
    IPC::Open3         (version 1.12)   #OPTIONAL Only needed by filterIndels.pl
    IO::Select         (version 1.21)   #OPTIONAL Only needed by filterIndels.pl
    IO::Pipe::Producer (version 1.8)    #OPTIONAL Only needed by filterIndels.pl
    Sys::Info          (version 0.78)   #OPTIONAL Only needed by filterIndels.pl
    File::Which        (version 1.09)   #OPTIONAL Will use `which` if not present

Dependent modules should be installed automatically, but if you wish to install them yourself, installing perl modules is easy if you use cpan.  You may have to answer a series of questions to set up cpan at first, but once it's setup, here's an example of the commands to install the module dependencies:

    env FTP_PASSIVE=1 PERL_MM_USE_DEFAULT=1 /usr/bin/perl -MCPAN -e shell
    > install Getopt::Long
    > install File::Glob
    > install IPC::Open3
    > install IO::Select
    > install IO::Pipe::Producer
    > install Sys::Info
    > install File::Which

To run filterIndels.pl without error, you need to have muscle installed and in your PATH.  If it's not in your path, you can supply the muscle executable with full path to the -y option.  You can install CFF without installing muscle.  If you want to run filterIndels.pl, you can install muscle at a later time.

To run getReals.pl with the -f option (implying candidates should be filtered for chimeras) without error, you need to have uchime installed and in your PATH.  If it's not in your path, you can supply the uchime executable with full path to the -y option.  You can install CFF without installing uchime.  If you want to run getReals.pl with -f, you can install uchime at a later time.

## EXAMPLE

In [1], we discuss the application of CFF to analyze a time series of 16S samples from a longitudinal study performed by Caporaso et al. [2]. As test data, we provide a subset of samples from that study. The same 10 samples are provided in FastA and FastQ format to illustrate the two uses of the CFF pipeline (using raw FastQ and already quality-filtered FastA data). For a detailed description of the test data, see samples/testDataDescription.txt.

### Example 1

Run these commands:

    cd samples
    tcsh run_example1.tcsh

Example 1 is roughly equivalent to running the following commands (the difference is that when you run the example script, the output files will be neatly organized in a number of subdirectories so you can follow the logic more easily):

    outdir=Caporaso_FASTA_out
    mergeSeqs.pl     Caporaso_FASTA/L6S2?_19???.fna -f example1.glib --outdir $outdir -o .lib -p ''
    neighbors.pl     $outdir/example1.glib -o .nbrs
    errorRates.pl    $outdir/example1.glib -n $outdir/example1.glib.nbrs -z 2 -o .erates
    nZeros.pl        $outdir/L6S2?_19???.fna.lib -n $outdir/example1.glib.nbrs -r $outdir/example1.glib.erates -o .n0s
    getCandidates.pl $outdir/L6S2?_19???.fna.lib.n0s -o .cands -f .rejects -h 30
    getReals.pl      $outdir/L6S2?_19???.fna.lib.n0s.cands -d '$outdir/L6S2?_19???.fna.lib' -f $outdir/example1.glib -k 2
    filterIndels.pl  $outdir/example1.glib.reals -o .filt -f .indels

Note that in the first command (mergeSeqs.pl), we turn off abundance value parsing from the fasta deflines by supplying -p ''.  While the command will work without -p '', it will generate an error because the default value for -p expects to see abundance patterns on deflines in the form "size=#;".  If you never intend to save abundance values on your deflines, you may supply --save-as-default -p '' to save the setting.

### Example 2

Run these commands:

    cd samples
    tcsh run_example2.tcsh

Example 2 runs CFF on FastQ test data. This executes pretty much the same commands, only it starts by performing minimal quality filtering using USEARCH (see [1]).


## REFERENCES

1. Tikhonov M, Leach RW, Wingreen NS. (2014) Interpreting 16S data without clustering to achieve sub-OTU resolution.  
 *A pre-print of this article, currently under review, is available upon request.*

2. [Caporaso JG, Lauber CL, Costello EK, et al. (2011) Moving pictures of the human microbiome. Genome Biol. 12(5):R50.] (http://dx.doi.org/10.1186/gb-2011-12-5-r50 "Caporaso et al., 2011")


## CONTACT

For technical support (bugs, feature requests, error messages, script functionality, portability...):  

https://github.com/hepcat72/CFF/issues

For science-related questions (usefulness of CFF for your application, limitations of error model, other sequencing platforms...):  

tikhonov@princeton.edu

## AUTHORS

Robert W. Leach  
Bioinformatics Group  
Lewis-Sigler Institute for Integrative Genomics  
Princeton University  
Princeton, NJ  

Mikhail Tikhonov  
Lewis-Sigler Institute for Integrative Genomics  
Princeton University  
Princeton, NJ  

## TROUBLESHOOTING

Using --verbose can sometimes help identify a problem.  Each script also comes with a debug mode.  Supply the --debug flag to help figure out issues.  Debug flags can be submitted multiple times, or with an integer parameter to increase the amount of debug output.  This will add line numbers to errors and warnings as well as print ongoing status messages and in some cases, calculation formulas.

## KNOWN ISSUES

none

## CHANGELOG

Changes are tracked via git and can be viewed on github for each individual script.
