#!/usr/bin/perl
#
# Copyright (c) 2007, Gerhard Poul All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer. Redistributions in binary
# form must reproduce the above copyright notice, this list of conditions and
# the following disclaimer in the documentation and/or other materials
# provided with the distribution. Neither the name of the ORGANIZATION nor
# the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission. 
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

use strict;
use warnings;

use File::Basename;

# This is the collector for iPhoto 6
# Currently highest error: MB0020E
my $debug = 0;

chdir;

# Define path to s3util binary
my $S3UTIL_BINARY = "/Users/gpoul/Projects/objc-s3/build/Release/s3util";

if (!-f $S3UTIL_BINARY) {
  die "Path to s3util is not correct: $S3UTIL_BINARY";
}

# Define accessKeyID
my $S3UTIL_ACCESSKEYID = "";

# Define bucket
my $S3UTIL_BUCKET = "";

# Make sure both of the above variables have been assigned
if ($S3UTIL_ACCESSKEYID eq "" || $S3UTIL_BUCKET eq "") {
  die "You need to define accessKeyID and bucket before using this script!"
}

# Make sure local cache is available and writeable

if (!-d ".mbackup") {
  mkdir(".mbackup") || die "MB0009E: Unable to create .mbackup local cache directory: $!";
}

# Make sure local collector directory exists

my $collectorDir = ".mbackup/iPhoto";

if (!-d $collectorDir) {
  mkdir($collectorDir) || die "MB0015E: Unable to create collector directory $collectorDir: $!";
}

# iPhoto Library base path

my $iPhotoLibBasePath = "Pictures/iPhoto Library";

# Backup base path

my $backupBasePath = "Desktop/mbackup-running";

# DMG MD5 SUM File

my $DMGSumFile = "DMGSumFile";

# Find the libraries that we're going to work on.

my @libraries = <"$iPhotoLibBasePath/Originals/*/*">;

foreach my $library (@libraries) {
  my $libraryRelativePath = $library;
  $libraryRelativePath =~ s/.*([0-9][0-9][0-9][0-9]\/.*)$/$1/;
  my $libraryName = $libraryRelativePath;
  my $libraryDisplayName = $libraryRelativePath;
  $libraryDisplayName =~ s/[0-9][0-9][0-9][0-9]\/(.*)$/$1/;
  $libraryName =~ s/\//-/g;
  $libraryName =~ s/\s/_/g;

  # Is this a new or an old library?
  if (-f "$collectorDir/$libraryName") {
    print "Checking existing iPhoto roll for changes: $libraryDisplayName.\n";
    archive_existinglib($library, $libraryRelativePath, $libraryName);
  } elsif (!-e "$collectorDir/$libraryName") {
    print "Found NEW iPhoto roll: $libraryDisplayName\n";
    archive_newlib($library, $libraryRelativePath, $libraryName);
  } else {
    die "MB0003E: Unable to read library metadata at $collectorDir/$libraryName!";
  }
}

sub archive_newlib {
  my $library = shift(@_);
  my $libraryRelativePath = shift(@_);
  my $libraryName = shift(@_);

  my @files = <"$iPhotoLibBasePath/Originals/$libraryRelativePath/*" "$iPhotoLibBasePath/Modified/$libraryRelativePath/*">;

  my %changeList;

  # Add all files as additions to the changeList.
  foreach my $file (@files) {
    $changeList{$file} = "A";
  }

  process_changelist(\%changeList, "initial", $library, $libraryRelativePath, $libraryName);
}

# Take a changeList and process it accordingly.
sub process_changelist {
  my $changeList = shift(@_);
  my $changeMode = shift(@_); # must be "delta" or "initial"
  my $library = shift(@_);
  my $libraryRelativePath = shift(@_);
  my $libraryName = shift(@_);

  if ($changeMode ne "delta" and $changeMode ne "initial") {
    die "MB0016E: Invalid changeMode \"$changeMode\".";
  }

  my %md5hash;
  my @files;

  my $dateString = `date +%Y%m%d`;
  chomp $dateString;

  foreach my $file (keys %{$changeList}) {
    # Added or modified files will be copied.
    if ($changeList->{$file} eq "A" || $changeList->{$file} eq "M") {
      push(@files, $file);
      print "pushing: $changeList->{$file} $file\n" if $debug;
    }
  }

  # Make sure this is a valid directory we can archive and generate MD5 hashes.
  foreach my $file (@files) {
    if (-f $file) {
      $md5hash{$file} = md5sum($file);
      print "PHOTO: $file - HASH: $md5hash{$file}\n" if ($debug);
    } elsif (-d $file) {
      die "MB0001E: There is a directory at $file. - This cannot be handled at this time!";
    } else {
      die "MB0002E: There is an unidentified object at $file. - This cannot be handled at this time!";
    }
  }

  # We now have a valid directory with all filenames and hash values in %md5hash.
  # Start to copy them to temporary directory so we can start creating a disk image.
  my $backupdir = "$backupBasePath/backup-iPhoto-$libraryName-$dateString";
  die "MB0004E: Backup directory does already exist. - Cancelling operation: $backupdir" if (-e $backupdir);
  if (!-d $backupBasePath) {
    mkdir($backupBasePath) || die "MB0006E: Cannot create backup directory: $!";
  }
  mkdir($backupdir) || die "MB0005E: Cannot create backup directory: $!";

  # What kind of photos do we have and what directories do we need to create?
  my $createOriginalsDirectory = 0;
  my $createModifiedDirectory = 0;

  foreach my $file (@files) {
    if ($file =~ /^$iPhotoLibBasePath\/Originals\/.*/) {
      $createOriginalsDirectory = 1;
      last;
    }
  }

  foreach my $file (@files) {
    if ($file =~ /^$iPhotoLibBasePath\/Modified\/.*/) {
      $createModifiedDirectory = 1;
      last;
    }
    print "NOMATCH: $file\n";
  }

  system("mkdir -p \"$backupdir/$iPhotoLibBasePath/Originals/$libraryRelativePath\"") if $createOriginalsDirectory;
  system("mkdir -p \"$backupdir/$iPhotoLibBasePath/Modified/$libraryRelativePath\"") if $createModifiedDirectory;
  foreach my $file (@files) {
    system("cp -p -n \"$file\" \"$backupdir/$file\""); # due to this being a system call we don't know if it was successful.
  }

  # Verify that copy was successful
  foreach my $file (@files) {
    if ($md5hash{$file} ne md5sum("$backupdir/$file")) {
      die "MB0007E: Hash was invalid for copied backup file!";
    }
  }

  # Write list of deleted files if this is a delta archive
  if ($changeMode eq "delta") {
    my $deletedFilesIndicator = 1;
    open(DFILE, ">$backupdir/DELETED-FILES.txt");
    foreach my $file (keys %{$changeList}) {
      if ($changeList->{$file} eq "D") {
        $deletedFilesIndicator = 0;
        print DFILE "$file\n";
      }
    }
    close(DFILE);
    unlink("$backupdir/DELETED-FILES.txt") if($deletedFilesIndicator);
  }

  # Save md5sums to local cache and into backup directory
  if (-e "$collectorDir/$libraryName") {
    if ($changeMode eq "delta") {
      my $count = 0;
      my $libraryBackupHashFileName;
      do {
        $count++;
        $libraryBackupHashFileName = "$collectorDir/$libraryName-$dateString-$count";
      } while (-e $libraryBackupHashFileName);
      system("cp \"$collectorDir/$libraryName\" \"$libraryBackupHashFileName\"");
      # Make sure copy was OK
      if (md5sum("$collectorDir/$libraryName") ne md5sum($libraryBackupHashFileName)) {
        die "MB0017E: Copy of hashfile to $libraryBackupHashFileName did not succeed.";
      }
    } else{
      die "MB0010E: I was going to write to $collectorDir/$libraryName, but it already exists, which it shouldn't!";
    }
  }

  my $nofilesIndicator = 1;

  open(BSUMFILE, ">$backupdir/MD5SUMS") || die "MB0011E: Can't open $backupdir/MD5SUMS for writing: $!";
  foreach my $file (keys %md5hash) {
    $nofilesIndicator = 0;
    print BSUMFILE "$file:$md5hash{$file}\n";
  }
  close(BSUMFILE);
  unlink("$backupdir/MD5SUMS") if($nofilesIndicator);

  # Don't use md5hash after this point, because it will be unuseable for the intended purpose.
  # If there is a reason to use md5hash contents after this point, you need to refactor the following source block.

  if ($changeMode ne "initial") {
    # Add all files that are unchanged to md5hash unless they've been deleted.

    open(SUMFILE, "$collectorDir/$libraryName") || die "MB0018E: Can't open $collectorDir/$libraryName for reading: $!";
    while(<SUMFILE>) {
      my ($filename, $hash) = /(.*):(.*)$/;
      if (!defined $md5hash{$filename}) {
        $md5hash{$filename} = $hash unless (defined $changeList->{$filename} && $changeList->{$filename} eq "D");
      }
    }
    close(SUMFILE);
  }

  open(SUMFILE, ">$collectorDir/$libraryName") || die "MB0008E: Can't open $collectorDir/$libraryName for writing: $!";
  foreach my $file (keys %md5hash) {
    print SUMFILE "$file:$md5hash{$file}\n";
  }
  close(SUMFILE);

  my %DMGSums;

  # Please be careful while handling $volname. - This is NOT only used to set the volname for hdiutil.

  my $volname;
  my $dmgfile;

  if ($changeMode eq "initial") {
    $volname = $libraryName;
    $dmgfile = "$backupBasePath/$libraryName.dmg";
  } else {
    open(DMGSUMFILE, "$collectorDir/$DMGSumFile") || die "MB0019E: Can't open $collectorDir/$DMGSumFile for reading: $!";
    while (<DMGSUMFILE>) {
      my ($filename, $hash) = /(.*):(.*)$/;
      $DMGSums{$filename} = $hash;
    }
    close(DMGSUMFILE);

    # Find the next available volume name.
    my $count = 0;
    do {
      $count++;
      $dmgfile = "$backupBasePath/$libraryName-$count.dmg";
    } while (defined $DMGSums{$dmgfile});
    $volname = "$libraryName-$count";
  }

  if ($debug) {
    print "\$dmgfile set to $dmgfile\n";
    print "\$volname set to $volname\n";
  }

  # Generate DMG
  system("hdiutil create -srcfolder \"$backupdir\" -fs HFS+ -encryption -volname \"$volname\" \"$dmgfile\"");
  if (-e "$dmgfile") {
    system("rm -rf \"$backupdir\"");
  } else {
    die "MB0012E: Unable to create disk image \"$dmgfile\"";
  }

  # Write the newly created DMG's MD5 sum to the SumFile.
  my $dmgMD5Sum = md5sum($dmgfile);
  open(DMGSUMFILE, ">>$collectorDir/$DMGSumFile") || die "MB0020E: Can't open $collectorDir/$DMGSumFile for appending: $!";
  print DMGSUMFILE "$dmgfile:$dmgMD5Sum\n";
  close(DMGSUMFILE);

  # Split into 100MB chunks and queue for uploading
  system("cd $backupBasePath && split -b 100m \"$volname.dmg\" \"$volname.dmg-\"") == 0
    or die "MB0013E: Unable to split file into chunks (return value: $?): $!";;
  if (-e "$dmgfile-aa") {
    # If there was only one split file created because the file was too small, save the original.
    if (!-e "$dmgfile-ab") {
      system("rm \"$dmgfile-aa\"");
      # Queue file for upload.
      upload($dmgfile);
    } else {
      system("rm \"$dmgfile\"");
      # Queue file for upload.
      upload(<$dmgfile-*>);
    }
  } else {
    die "MB0014E: Unable to split file into chunks, but split did return OK";
  }
}

sub archive_existinglib {
  my $library = shift(@_);
  my $libraryRelativePath = shift(@_);
  my $libraryName = shift(@_);

  my %md5hash;

  # Look for changes using MD5 hashes
  open(SUMFILE, "$collectorDir/$libraryName") || die "MB0015E: Can't open $collectorDir/$libraryName for reading: $!";
  while(<SUMFILE>) {
    my ($filename, $hash) = /(.*):(.*)$/;
    print "Loaded hash: $filename - (MD5: $hash)\n" if $debug;
    $md5hash{$filename} = $hash;
  }
  close(SUMFILE);

  my %changeList;

  foreach my $file (keys %md5hash) {
    if (-e $file) {
      if ($md5hash{$file} ne md5sum($file)) {
        $changeList{$file} = "M";
      }
    } else {
      $changeList{$file} = "D";
    }
  }

  # Look for additions
  my @files = <"$iPhotoLibBasePath/Originals/$libraryRelativePath/*" "$iPhotoLibBasePath/Modified/$libraryRelativePath/*">;

  foreach my $file (@files) {
    if(!defined $md5hash{$file}) {
      $changeList{$file} = "A";
    }
  }

  # Print changelist if debug mode is enabled
  if ($debug) {
    foreach my $file (keys %changeList) {
      print "$changeList{$file} $file\n";
    }
  }

  # Process whatever has changed.
  if (keys %changeList) {
    process_changelist(\%changeList, "delta", $library, $libraryRelativePath, $libraryName);
  }
}

sub md5sum {
  my $file = shift(@_);

  my $hash = `md5 \"$file\"`;
  chomp $hash;
  $hash =~ s/.*= (.*)$/$1/;

  return $hash;
}

sub upload {
  foreach my $file (@_) {
    my $size = -s $file;
    print "Uploading $file ($size bytes)\n";

    # Calculate path of file for system() call
    my $dir = dirname($file);
    my $uploadname = basename($file);
    my $homedir = $ENV{"HOME"};

    system("cd $dir; $S3UTIL_BINARY --accessKeyID $S3UTIL_ACCESSKEYID --bucket $S3UTIL_BUCKET --persistMD5 $homedir/$collectorDir/backupsums --upload \"$uploadname\"; cd");

    print "s3util terminated. Please press return to continue...";
    readline(*STDIN);
  }
}
