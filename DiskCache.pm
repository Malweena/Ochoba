package DiskCache;

use strict;
use File::Copy;
use Encode;
use utf8;
use Fcntl qw/:flock/;

sub new {
my $self = {};
%{$self}=%{$_[1]};

$self->{extpaths}={} unless($self->{extpaths});
foreach my $cpath(@{$self->{cachepaths}}){mkdir($cpath) unless(-d($cpath));
#if($self->{thumbpath}){mkdir("$cpath/$self->{thumbpath}") unless(-d("$cpath/$self->{thumbpath}"))};
for(values %{$self->{extpaths}}){mkdir("$cpath/$_") unless(-d("$cpath/$_"))}
}

bless $self;
return $self; }
#######################################################################

sub save {
my ($self,$cachepath,$file,$data,$path,$rw)=@_;
Encode::_utf8_on($file);
$file=~s|^.*?([^/\\]*)\.([A-z]*)$|$1|;
my $ext=lc($2);

$file=~s/[^А-яA-z0-9]//g;

unless($path and -d("$cachepath/$path")){

  if($self->{extpaths}{$ext}){$path=$self->{extpaths}{$ext}}else{return;}
}

if(!$rw and -e("$cachepath/$path/$file.$ext")){do{$file.=int(rand(9))}while(-e("$cachepath/$path/$file.$ext"));}

open my $fhandle,'>',"$cachepath/$path/$file.$ext" or return;
flock($fhandle,LOCK_EX);
binmode($fhandle);

if(ref($data) eq 'Fh' or ref($data) eq 'GLOB'){
  binmode($data);
  copy($data,$fhandle) or return;
}else {print $fhandle $data;}
close $fhandle;
close $data;

return "$path/$file.$ext";
}
#################
sub delete {my ($self,$cachepath,@files)=@_; unlink "$cachepath/$_" for(@files);}
#################
sub exist {my ($self,$cachepath,$file)=@_; return (-e("$cachepath/$file"));}

##########################################

1;