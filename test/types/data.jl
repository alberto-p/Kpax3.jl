# This file is part of Kpax3. License is MIT.

##############
# Exceptions #
##############
@test_throws KDomainError NucleotideData("data/proper_nt.fasta",
                                         miss=['\0', '?'])
@test_throws KDomainError NucleotideData("data/proper_nt.fasta", l=-1)

@test_throws KFASTAError NucleotideData("data/empty_file.fasta")
@test_throws KFASTAError NucleotideData("data/no_1st_seq.fasta")
@test_throws KFASTAError NucleotideData("data/no_id_char.fasta")
@test_throws KFASTAError NucleotideData("data/no_nth_seq.fasta")

@test_throws TypeError NucleotideData("data/utf8_id.fasta")
@test_throws TypeError NucleotideData("data/utf8_seq.fasta")

@test_throws KDomainError AminoAcidData("data/proper_nt.fasta",
                                        miss=['\0', '?'])
@test_throws KDomainError AminoAcidData("data/proper_nt.fasta", l=-1)

@test_throws KFASTAError AminoAcidData("data/empty_file.fasta")
@test_throws KFASTAError AminoAcidData("data/no_1st_seq.fasta")
@test_throws KFASTAError AminoAcidData("data/no_id_char.fasta")
@test_throws KFASTAError AminoAcidData("data/no_nth_seq.fasta")

@test_throws TypeError AminoAcidData("data/utf8_id.fasta")
@test_throws TypeError AminoAcidData("data/utf8_seq.fasta")

#################################
# FASTA file filled with blanks #
#################################
nt = NucleotideData("data/blanks.fasta")
@test nt.data == UInt8[0 1;
                       1 0;
                       1 0;
                       0 1;
                       0 1;
                       1 0;
                       1 0;
                       0 1;
                       1 0;
                       0 1;
                       0 1;
                       1 0]
@test nt.id == ASCIIString["ID1", "ID5"]
@test nt.ref == UInt8[1, 4, 3, 29, 29, 29, 3, 29, 29, 1, 29, 1]
@test nt.val == UInt8[1, 3, 1, 3, 2, 3, 2, 3, 1, 3, 2, 3]
@test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]

nt = NucleotideData("data/blanks.fasta", l=1)
@test nt.data == UInt8[0 1;
                       1 0;
                       1 0;
                       0 1;
                       0 1;
                       1 0;
                       1 0;
                       0 1;
                       1 0;
                       0 1;
                       0 1;
                       1 0]
@test nt.id == ASCIIString["ID1", "ID5"]
@test nt.ref == UInt8[1, 4, 3, 29, 29, 29, 3, 29, 29, 1, 29, 1]
@test nt.val == UInt8[1, 3, 1, 3, 2, 3, 2, 3, 1, 3, 2, 3]
@test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]

aa = AminoAcidData("data/blanks.fasta")
@test aa.data == UInt8[0 1;
                       1 0;
                       1 0;
                       0 1;
                       0 1;
                       1 0;
                       1 0;
                       0 1;
                       1 0;
                       0 1;
                       0 1;
                       1 0]
@test aa.id == ASCIIString["ID1", "ID5"]
@test aa.ref == UInt8[1, 4, 3, 29, 29, 29, 3, 29, 29, 1, 29, 1]
@test aa.val == UInt8[1, 3, 1, 3, 2, 3, 2, 3, 1, 3, 2, 3]
@test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]

aa = AminoAcidData("data/blanks.fasta", l=1)
@test aa.data == UInt8[0 1;
                       1 0;
                       1 0;
                       0 1;
                       0 1;
                       1 0;
                       1 0;
                       0 1;
                       1 0;
                       0 1;
                       0 1;
                       1 0]
@test aa.id == ASCIIString["ID1", "ID5"]
@test aa.ref == UInt8[1, 4, 3, 29, 29, 29, 3, 29, 29, 1, 29, 1]
@test aa.val == UInt8[1, 3, 1, 3, 2, 3, 2, 3, 1, 3, 2, 3]
@test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]

#########################
# Proper DNA FASTA file #
#########################
nt = NucleotideData("data/proper_nt.fasta")
@test nt.data == UInt8[0 0 0 0 0 1;
                       1 1 1 1 1 0;
                       0 0 1 0 1 1;
                       1 1 0 1 0 0;
                       1 1 0 0 0 0;
                       0 0 0 1 1 0;
                       0 0 0 1 1 1;
                       1 1 1 0 0 0;
                       0 0 1 0 0 0;
                       1 0 0 1 0 1;
                       0 1 0 0 1 0;
                       1 1 1 0 0 0;
                       0 0 0 1 1 0;
                       0 0 0 0 0 1;
                       1 1 0 0 1 1;
                       0 0 1 1 0 0;
                       0 1 0 0 1 0;
                       1 0 1 1 0 1]
@test nt.id == ASCIIString["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
@test nt.ref == UInt8[1, 29, 3, 29, 29, 29, 3, 29, 29, 29, 29, 1]
@test nt.val == UInt8[2, 4, 1, 3, 1, 3, 2, 3, 1, 2, 3, 1, 3, 4, 1, 4, 2, 3]
@test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

nt = NucleotideData("data/proper_nt.fasta", l=1)
@test nt.data == UInt8[0 0 0 0 0 1;
                       1 1 1 1 1 0;
                       0 0 1 0 1 1;
                       1 1 0 1 0 0;
                       1 1 0 0 0 0;
                       0 0 0 1 1 0;
                       0 0 0 1 1 1;
                       1 1 1 0 0 0;
                       0 0 1 0 0 0;
                       1 0 0 1 0 1;
                       0 1 0 0 1 0;
                       1 1 1 0 0 0;
                       0 0 0 1 1 0;
                       0 0 0 0 0 1;
                       1 1 0 0 1 1;
                       0 0 1 1 0 0;
                       0 1 0 0 1 0;
                       1 0 1 1 0 1]
@test nt.id == ASCIIString["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
@test nt.ref == UInt8[1, 29, 3, 29, 29, 29, 3, 29, 29, 29, 29, 1]
@test nt.val == UInt8[2, 4, 1, 3, 1, 3, 2, 3, 1, 2, 3, 1, 3, 4, 1, 4, 2, 3]
@test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

# consider all characters
nt = NucleotideData("data/proper_nt.fasta", miss=['\0'])
@test nt.data == UInt8[0 0 0 0 0 1;
                       1 1 1 1 1 0;
                       0 0 1 0 1 1;
                       1 1 0 1 0 0;
                       1 1 0 0 0 0;
                       0 0 0 1 1 0;
                       0 0 1 0 0 1;
                       0 0 0 1 1 1;
                       1 1 1 0 0 0;
                       0 0 1 0 0 0;
                       1 0 0 1 0 1;
                       0 1 0 0 1 0;
                       1 1 1 0 0 0;
                       0 0 0 1 1 0;
                       0 0 0 0 0 1;
                       1 1 0 0 1 1;
                       0 0 1 1 0 0;
                       0 1 0 0 1 0;
                       1 0 1 1 0 1;
                       1 0 1 1 1 1;
                       0 1 0 0 0 0]
@test nt.id == ASCIIString["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
@test nt.ref == UInt8[1, 29, 3, 29, 29, 29, 3, 29, 29, 29, 29, 29]
@test nt.val == UInt8[2, 4, 1, 3, 1, 3, 28, 2, 3, 1, 2, 3, 1, 3, 4, 1, 4, 2, 3,
                      1, 28]
@test nt.key == [1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8, 9, 9]

#############################
# Proper Protein FASTA file #
#############################
aa = AminoAcidData("data/proper_aa.fasta")
@test aa.data == UInt8[0 0 0 0 0 1;
                       1 1 1 1 1 0;
                       0 0 1 0 1 1;
                       1 1 0 1 0 0;
                       1 1 0 0 0 0;
                       0 0 0 1 1 0;
                       1 1 1 0 0 0;
                       0 0 0 1 1 1;
                       0 0 1 0 0 0;
                       1 0 0 1 0 1;
                       0 1 0 0 1 0;
                       0 0 0 0 0 1;
                       1 1 1 0 0 0;
                       0 0 0 1 1 0;
                       1 1 0 0 1 1;
                       0 0 1 1 0 0;
                       1 1 0 1 0 0;
                       0 0 1 0 1 1]
@test aa.id == ASCIIString["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
@test aa.ref == UInt8[14, 29, 1, 29, 29, 29, 20, 29, 29, 29, 29, 15]
@test aa.val == UInt8[9, 13, 11, 13, 12, 20, 12, 20, 2, 4, 12, 9, 12, 14, 2, 19,
                      1, 4]
@test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

aa = AminoAcidData("data/proper_aa.fasta", l=1)
@test aa.data == UInt8[0 0 0 0 0 1;
                       1 1 1 1 1 0;
                       0 0 1 0 1 1;
                       1 1 0 1 0 0;
                       1 1 0 0 0 0;
                       0 0 0 1 1 0;
                       1 1 1 0 0 0;
                       0 0 0 1 1 1;
                       0 0 1 0 0 0;
                       1 0 0 1 0 1;
                       0 1 0 0 1 0;
                       0 0 0 0 0 1;
                       1 1 1 0 0 0;
                       0 0 0 1 1 0;
                       1 1 0 0 1 1;
                       0 0 1 1 0 0;
                       1 1 0 1 0 0;
                       0 0 1 0 1 1]
@test aa.id == ASCIIString["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
@test aa.ref == UInt8[14, 29, 1, 29, 29, 29, 20, 29, 29, 29, 29, 15]
@test aa.val == UInt8[9, 13, 11, 13, 12, 20, 12, 20, 2, 4, 12, 9, 12, 14, 2, 19,
                      1, 4]
@test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

# consider all characters
aa = AminoAcidData("data/proper_aa.fasta", miss=['\0'])
@test aa.data == UInt8[0 0 0 0 0 1;
                       1 1 1 1 1 0;
                       0 0 1 0 1 1;
                       1 1 0 1 0 0;
                       1 1 0 0 0 0;
                       0 0 0 1 1 0;
                       0 0 1 0 0 1;
                       1 1 1 0 0 0;
                       0 0 0 1 1 1;
                       0 0 1 0 0 0;
                       1 0 0 1 0 1;
                       0 1 0 0 1 0;
                       0 0 0 0 0 1;
                       1 1 1 0 0 0;
                       0 0 0 1 1 0;
                       1 1 0 0 1 1;
                       0 0 1 1 0 0;
                       1 1 0 1 0 0;
                       0 0 1 0 1 1;
                       1 0 1 1 1 1;
                       0 1 0 0 0 0]
@test aa.id == ASCIIString["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
@test aa.ref == UInt8[14, 29, 1, 29, 29, 29, 20, 29, 29, 29, 29, 29]
@test aa.val == UInt8[9, 13, 11, 13, 12, 20, 28, 12, 20, 2, 4, 12, 9, 12, 14, 2,
                      19, 1, 4, 15, 28]
@test aa.key == [1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8, 9, 9]

####################
# Input and Output #
####################
nt = NucleotideData("data/proper_nt.fasta")

# TODO: Test exception when saving to a location without writing permissions
save("../build/nt.jld", nt)
@test isfile("../build/nt.jld")

@test_throws SystemError loadnt("../build/non_existent.file")

nt = loadnt("../build/nt.jld")

@test isa(nt, NucleotideData)
@test nt.data == UInt8[0 0 0 0 0 1;
                       1 1 1 1 1 0;
                       0 0 1 0 1 1;
                       1 1 0 1 0 0;
                       1 1 0 0 0 0;
                       0 0 0 1 1 0;
                       0 0 0 1 1 1;
                       1 1 1 0 0 0;
                       0 0 1 0 0 0;
                       1 0 0 1 0 1;
                       0 1 0 0 1 0;
                       1 1 1 0 0 0;
                       0 0 0 1 1 0;
                       0 0 0 0 0 1;
                       1 1 0 0 1 1;
                       0 0 1 1 0 0;
                       0 1 0 0 1 0;
                       1 0 1 1 0 1]
@test nt.id == ASCIIString["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
@test nt.ref == UInt8[1, 29, 3, 29, 29, 29, 3, 29, 29, 29, 29, 1]
@test nt.val == UInt8[2, 4, 1, 3, 1, 3, 2, 3, 1, 2, 3, 1, 3, 4, 1, 4, 2, 3]
@test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

aa = AminoAcidData("data/proper_aa.fasta")

# TODO: Test exception when saving to a location without writing permissions
save("../build/aa.jld", aa)
@test isfile("../build/aa.jld")

@test_throws SystemError loadaa("../build/non_existent.file")

aa = loadaa("../build/aa.jld")
@test isa(aa, AminoAcidData)
@test aa.data == UInt8[0 0 0 0 0 1;
                       1 1 1 1 1 0;
                       0 0 1 0 1 1;
                       1 1 0 1 0 0;
                       1 1 0 0 0 0;
                       0 0 0 1 1 0;
                       1 1 1 0 0 0;
                       0 0 0 1 1 1;
                       0 0 1 0 0 0;
                       1 0 0 1 0 1;
                       0 1 0 0 1 0;
                       0 0 0 0 0 1;
                       1 1 1 0 0 0;
                       0 0 0 1 1 0;
                       1 1 0 0 1 1;
                       0 0 1 1 0 0;
                       1 1 0 1 0 0;
                       0 0 1 0 1 1]
@test aa.id == ASCIIString["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
@test aa.ref == UInt8[14, 29, 1, 29, 29, 29, 20, 29, 29, 29, 29, 15]
@test aa.val == UInt8[9, 13, 11, 13, 12, 20, 12, 20, 2, 4, 12, 9, 12, 14, 2, 19,
                      1, 4]
@test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]