use GD;

sub filter_html{
my ($ref)=@_;
  	${$ref}=~s/\</&lt;/g;
	${$ref}=~s/\>/&gt;/g;
	${$ref}=~s/"/&quot;/g;
	${$ref}=~s/'/&#39;/g;
	${$ref}=~s/,/&#44;/g;
    ${$ref}=~s/\\/&quot;/g, 
    ${$ref}=~s/‘/&lsquo;/g;
    ${$ref}=~s/’/&rsquo;/g; 
	${$ref}=~s/“/&ldquo;/g;
	${$ref}=~s/”/&rdquo;/g; 
    ${$ref}=~s/„/&bdquo;/g;
	${$ref}=~s/‹/&lsaquo;/g;
	${$ref}=~s/›/&rsaquo;/g;
	${$ref}=~s/€/&euro;/g; 
    ${$ref}=~s/§/&sect;/g;
	${$ref}=~s/©/&copy;/g;
	${$ref}=~s/«/&laquo;/g;
	${$ref}=~s/»/&raquo;/g; 
    ${$ref}=~s/®/&reg;/g;
	${$ref}=~s/°/&deg;/g;
}

sub create_captcha{
	my ($CAP_FONT, $CAP_WORDS)=@_;

	
	my ($word,$hash);
	my @s=('a'..'z',0..9);
	$hash.=$s[rand(@s)] for(1...32);
	$word.=${$_}[rand(@{$_})] for(values %{$CAP_WORDS});

	my $img =GD::Image->new(175,30,1);
	$img->fill(1,1,$img->colorAllocate(255,255,255));

	$img->stringFT($img->colorAllocate(0,0,0),$CAP_FONT,18,0,5,27,$word);

  
	open my $imgfile, '>captchas/'.$hash.'.png';
	binmode($imgfile);
	print $imgfile $img->png();
	close $imgfile;

	return ($hash,$word);
}



sub hide_data($$$$)
{
	my ($data,$bytes,$key,$secret)=@_;

	my $crypt=rc4("\0"x$bytes,rc4("\0" x 32 ,$key.$secret).$data);

	return encode_base64($crypt,'');
}

sub encode_base64($;$) # stolen from MIME::Base64::Perl
{
	my ($data,$eol)=@_;
	$eol="\n" unless(defined $eol);

	my $res=pack "u",$data;
	$res=~s/^.//mg; # remove length counts
	$res=~s/\n//g; # remove newlines
	$res=~tr|` -_|AA-Za-z0-9+/|; # translate to base64

	my $padding=(3-length($data)%3)%3; 	# fix padding at the end
	$res=~s/.{$padding}$/'='x$padding/e if($padding);

	$res=~s/(.{1,76})/$1$eol/g if(length $eol); # break encoded string into lines of no more than 76 characters each

	return $res;
}

sub rc4($$;$)
{
	my ($message,$key,$skip)=@_;
	my @s=0..255;
	my @k=unpack 'C*',$key;
	my @message=unpack 'C*',$message;
	my ($x,$y);
	$skip=256 unless(defined $skip);

	$y=0;
	for $x (0..255)
	{
		$y=($y+$s[$x]+$k[$x%@k])%256;
		@s[$x,$y]=@s[$y,$x];
	}

	$x=0; $y=0;
	for(1..$skip)
	{
		$x=($x+1)%256;
		$y=($y+$s[$x])%256;
		@s[$x,$y]=@s[$y,$x];
	}

	for(@message)
	{
		$x=($x+1)%256;
		$y=($y+$s[$x])%256;
		@s[$x,$y]=@s[$y,$x];
		$_^=$s[($s[$x]+$s[$y])%256];
	}

	return pack 'C*',@message;
}


'няк';