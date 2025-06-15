package RealplexorApi;

use strict;
use Socket;
use bytes;
use JSON::XS;
##############
sub new { 
my $self = $_[1];

$self->{addr}=sockaddr_in($self->{port},inet_aton($self->{host}));
$self->{proto}=getprotobyname('tcp');

$self->{json} = JSON::XS->new();
$self->{json}->utf8(1);
$self->{json}->allow_nonref(1);

bless $self;
return $self; 
}

##############
sub watchOnline{
	my ($self,$pos,@channels)=@_;
	my $data=[];
	
	my $response=$self->_send('','watch '.$pos.(@channels ? ' '.join(' ',@channels) : ''),1);
	my @lines=split "\n",$response;
	
	for(@lines){
		m/^ (\w+) \s+ ([^:]+):(\S+) \s* $/sxg;
		push @{$data},{	event => $1,pos   => $2,id    => $3,};
	}
	return $data;
}

sub online{
	my ($self,@channels)=@_;
	my $return={};
	
	my $response=$self->_send('','online '.join(' ',@channels),1);
	
	$return->{$1}=$2 while($response=~m/([^ \n]*) ([^ \n]*)/g);
	
	return $return;
}

sub send_data {
	my ($self,$ids,$data,$showonlyfor)=@_;
	my (@pairs,$k,$v);
	
	if(ref($ids) eq 'HASH'){
		push @pairs, "$v:$k" while(($k,$v)=each %{$ids});
	}
	else{
		push @pairs, $_ for(@{$ids});
	}
	if($showonlyfor){push @pairs, '*'.$_ for(@{$showonlyfor});};
	
	$self->_send(join(',',@pairs),$self->{json}->encode($data));
}


sub _send{
	my ($self,$identifier,$data,$wait)=@_;
	
	my $request = 
	 "POST / HTTP/1.1\r\n"
	."Host: $self->{host}\r\n"
	.'Content-Length: '.length($data)."\r\n"
	.'X-Realplexor: identifier=' 
	.($self->{login} ? $self->{login}.':'.$self->{password}.'@':'')
	.$identifier
	."\r\n\r\n"
	.$data."\n\n";
	
	socket(my $socket, PF_INET, SOCK_STREAM, $self->{proto});
	
	connect($socket, $self->{addr}) or die "RealplexorApi: Can`t connect to server$self->{host}:$self->{port}!\n";
	
	send ($socket, $request, 0) or do{warn "RealplexorApi: Can`t send $data !";};
	
	
	if($wait){
		my $result;
		$result .= $_ while($_ = readline($socket));
		close $socket;
		
	  my ($result,$body)=split m'\r?\n\r?\n',$result;
	  
		unless($result=~m{^HTTP/[\d.]+ \s+ ((\d+) [^\r\n]*)}six){
			warn 'Non-HTTP response received: '.$result;
			return;
		}
		unless(int($2) == 200){
			warn 'Request failed: '.$1."\n";
			return;
		}
		unless($result=~m/^Content-Length: \s* (\d+)/mix){
			warn 'No Content-Length header in response headers: '.$result;
			return;
		}
		unless(int ($1) == length($body)){
			warn 'Response length '.length($body)." is different than specified in Content-Length header $1: possibly broken response\n";
			return;
		}
	  return $body;
	}
	close $socket;
}

'nyak-nyak';