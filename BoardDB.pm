package BoardDB;

use strict;
use MongoDB;
use Data::Dumper;
use Tie::IxHash;
use utf8;
##############

sub new {
	my $self = $_[1];
	# boards  => [] , connection =>{}
	bless $self;

	$self->{connection} = $self->{connection} ? MongoDB::Connection->new(%{$self->{connection}}) : MongoDB::Connection->new();
	
	
	my $initcoll; 
	for(@{$self->{boards}}){ 
		
		#если база новая, то создаем индексы у threads и счетчик постов в posts
		my @collnames=$self->{connection}->$_->collection_names;
		for(@collnames){$initcoll=1 if($_ eq 'threads');};
		unless($initcoll){$self->{connection}->$_->threads->ensure_index({lasthit => -1 , sticked => -1});};
		
		$initcoll=0;
		for(@collnames){$initcoll=1 if($_ eq 'posts');};
		unless($initcoll){$self->{connection}->$_->posts->save({_id =>0, counter => 0});};
		
		##
		$self->{dbs}{$_}{threads}=$self->{connection}->$_->threads;
		$self->{dbs}{$_}{posts}=$self->{connection}->$_->posts;
 
	}
	
	$self->{sorting} = Tie::IxHash->new(sticked => -1, lasthit => -1);

	return $self; 
}

###############Счетчик постов###

sub getCounter { # $self, $board
	return ${$_[0]->{dbs}{$_[1]}{posts}->find_one({_id =>0})}{'counter'};
}

sub setCounter { # $self, $board, $newcount
	$_[0]->{dbs}{$_[1]}{posts}->save({_id =>0, counter => $_[2]});
}

sub Counter{ # $self , $board, +-$num
	$_[0]->{dbs}{$_[1]}{posts}->update({_id => 0}, {'$inc' => {counter => 1}});
	return ${$_[0]->{dbs}{$_[1]}{posts}->find_one({_id =>0})}{counter};
}

###Проверка на существование

sub checkThread{ # $self, $board, $thread
	$_=$_[0]->{dbs}{$_[1]}{threads}->find_one({ '_id' => int $_[2] });
	return 0 unless($_);
	return 0 if($_->{closed});
	return 1;
}

sub checkPost{ # $self, $board, $post
	return 1 if($_[0]->{dbs}{$_[1]}{posts}->count({ '_id' => int $_[2] }));
}

######Работа с постами#########

sub addPost { # добавление поста
my ($self,$board,$post)= @_;

		$ENV{TZ} = 'Europe/Moscow';
		my @days=qw(Вск Пнд Втр Срд Чтв Птн Сбт);
		my @months=qw(Янв Фев Мар Апр Май Июн Июл Авг Сен Окт Ноя Дек);
	$post->{time}=time; my ($sec,$min,$hour,$mday,$mon,$year,$wday)=localtime($post->{time});
	$post->{date}= sprintf($self->{datestyle},$days[$wday],$mday,$months[$mon],$year+1900,$hour,$min,$sec);

	$post->{_id} = $self->Counter($board,1);
	$self->{dbs}{$board}{posts}->save($post);

	return $post->{_id};
}

sub setPost { #изменение поста
	my ($self,$board,$post)= @_;

	$self->{dbs}{$board}{posts}->update({_id =>int(delete $post->{_id}) }, { '$set' => $post   }, {upsert => 1});
}

sub getPosts {
	return $_[0]->{dbs}{$_[1]}{posts}->find({ '_id' =>{'$in'=> $_[2]} },{sort_by=>{ _id => 1}})->all;
}

sub deletePosts{
	$_[0]->{dbs}{$_[1]}{posts}->remove({ '_id' =>{'$in'=>$_[2]} });
}
####################################

##############Работа с тредами######
sub setThread{ #создание или изменение данных треда
	my ($self,$board,$thread)= @_;
	
	$self->{dbs}{$board}{threads}->update({_id =>int(delete $thread->{_id}) }, { '$set' => $thread  }, {upsert => 1});
}

sub delThread{ #Удаление треда вместе с постами
	my ($self,$board,$thread)= @_;
	return 0 unless($_ = $self->{dbs}{$board}{threads}->find_one({_id =>int $thread }));
  
	my @posts=$self->{dbs}{$board}{posts}->find({ '_id' =>{'$in'=> $_->{posts}} })->all;
	foreach my $post(@posts){
		for(@{$post->{files}}){
			unlink $board.'/'.$_->{filepath};
			unlink $board.'/'.$_->{thumbnail} if($_->{twidth} and $_->{theight});
		}
	}
	$self->{dbs}{$board}{posts}->remove({ _id =>{'$in'=> $_->{posts} }}); 
	$self->{dbs}{$board}{threads}->remove({ _id =>int $thread });
	unlink $board.'/'.$self->{threadpath}.'/'.$_->{_id}.'.'.$self->{thrext};
}

sub postToThread{ #добавление списка постов в тред
	my ($self,$board,$thread,$posts,$bumplimit)= @_;
	my $data=$self->{dbs}{$board}{threads}->find_one({_id =>int $thread });
	push @{$data->{posts}},@{$posts};
  
	$data->{lasthit}=time if($bumplimit && !(scalar(@{$data->{posts}})>$bumplimit));
  
	$self->{dbs}{$board}{threads}->save($data);
}


sub delFromThread{ #удаление списка постов из треда
	my ($self,$board,$thread,$posts)= @_;
	my $data=$self->{dbs}{$board}{threads}->find_one({_id =>int $thread });
  
	my (@indexes,$i);
	foreach my $post(@{$data->{posts}}){
		for(@{$posts}){
			if($_ == $post){push @indexes,$i; last;} 
		}
		$i++;
	}; $i=0;
	for(@indexes){splice @{$data->{posts}},$_-$i,1; $i++} 
 
	$self->{dbs}{$board}{threads}->save($data);
}

sub getThread{ #Получение треда вместе с постами
	my ($self,$board,$thread)= @_; 
	
	return {} unless($_ = $self->{dbs}{$board}{threads}->find_one({_id =>int $thread }));
	
	$_->{postscount}=scalar(@{$_->{posts}});
	$_->{posts}=[$self->{dbs}{$board}{posts}->find({ _id =>{'$in'=> $_->{posts} }},{sort_by=>{ _id => 1}})->all];
	
	return $_;
}

sub stickThread{
	my ($self,$board,$thread)= @_; 
	
	return 0 unless($_ = $self->{dbs}{$board}{threads}->find_one({_id =>int $thread }));
	
	if($_->{sticked}){$_->{sticked}=0}else{$_->{sticked}=1};
	$self->{dbs}{$board}{threads}->save($_);
	
	return $_->{sticked};
}

sub closeThread{
	my ($self,$board,$thread)= @_; 
	
	return 0 unless($_ = $self->{dbs}{$board}{threads}->find_one({_id =>int $thread }));
	if($_->{closed}){$_->{closed}=0}else{$_->{closed}=1};
	$self->{dbs}{$board}{threads}->save($_);
	
	return $_->{closed};
}

sub unBump{ #Откат lasthit на таймстамп последнего поста
	my ($self,$board,$thread)= @_; 
	
	return unless($_ = $self->{dbs}{$board}{threads}->find_one({_id =>int $thread }));
	
	$_->{lasthit}=$self->{dbs}{$board}{posts}->find_one({ _id =>@{$_->{posts}}[-1]})->{time};
	$self->{dbs}{$board}{threads}->save($_);
}

sub getThreads{ #Получение списка тредов
	return $_[0]->{dbs}{$_[1]}{threads}->find({},{sort_by=>$_[0]->{sorting}})->all;
}


###########Работа со страницами

sub countPages {
	my ($self,$board,$threads)= @_; # борда , тредов на страницу 
	$_=$self->{dbs}{$board}{threads}->count();
	return 0 unless($_);
	
	if(int($_/$threads) < $_/$threads){ return int($_/$threads);}else{return (int($_/$threads)-1);}
}


sub getPages{
	my ($self,$board,$threads,$posts)= @_; # борда , тредов на страницу, последних постов из треда 
	my (@pages,$op);
	
	my @threads = $self->{dbs}{$board}{threads}->find({},{sort_by=>$self->{sorting}})->all;
  
	while(my @pagethreads=splice @threads,0,$threads){
	
		foreach(@pagethreads){
			$_->{postscount}=scalar(@{$_->{posts}});

			if($posts<=$_->{postscount}){
				$_->{posts}=[$self->{dbs}{$board}{posts}->find({ _id =>{'$in'=> [${$_->{posts}}[0],splice(@{$_->{posts}}, -$posts)] }},{sort_by=>{ _id => 1}})->all];
			}
			else
			{
				$_->{posts}=[$self->{dbs}{$board}{posts}->find({ _id =>{'$in'=> $_->{posts} }},{sort_by=>{ _id => 1}})->all];
			}
		}
		
	push @pages,\@pagethreads;
	}

	return \@pages;
}

sub getPage{
	my ($self,$board,$page,$threads,$posts)= @_; # борда , номер страницы, тредов на страницу, последних постов из треда 
	my $op;
	my @pagethreads = $self->{dbs}{$board}{threads}->find({},{sort_by=>$self->{sorting}, limit => $threads, skip => $page*$threads })->all;
  
	foreach(@pagethreads){
		$_->{postscount}=scalar(@{$_->{posts}});

		if($posts<=$_->{postscount}){
			$_->{posts}=[$self->{dbs}{$board}{posts}->find({ _id =>{'$in'=> [${$_->{posts}}[0],splice(@{$_->{posts}}, -$posts)] }},{sort_by=>{ _id => 1}})->all];
		}
		else
		{
			$_->{posts}=[$self->{dbs}{$board}{posts}->find({ _id =>{'$in'=> $_->{posts} }},{sort_by=>{ _id => 1}})->all];
		}
		
	}
	
	return \@pagethreads;
}

###########
sub clearPage { # очистка страницы
	my ($self,$board,$page,$threads)= @_; # борда , номер страницы, тредов на страницу
	
	my @pagethreads = $self->{dbs}{$board}{threads}->find({},{sort_by=>$self->{sorting}, limit => $threads, skip => $page*$threads })->all;
	my ($posts,$threads)=([],[]);
	
	foreach (@pagethreads){
		push @{$posts},@{$_->{posts}};
		push @{$threads},$_->{_id};
		
		unlink $board.'/'.$self->{threadpath}.'/'.$_->{_id}.'.'.$self->{thrext};
	}
	
	my $postslist=$self->{dbs}{$board}{posts}->find({ _id =>{'$in'=> $posts} });
	my $post;
	
	while($post=$postslist->next){
		for(@{$post->{files}}){
			unlink $board.'/'.$_->{filepath};
			unlink $board.'/'.$_->{thumbnail} if($_->{twidth} and $_->{theight});
		}
	}
	
	$self->{dbs}{$board}{posts}->remove({ _id =>{'$in'=> $posts }}); 
	$self->{dbs}{$board}{threads}->remove({ _id =>{'$in'=> $threads }});
	
}


sub deleteFiles{
	my ($self,$board,$files)=@_;
	
	for(@{$files}){
		unlink $board.'/'.$_->{filepath};
		unlink $board.'/'.$_->{thumbnail} if($_->{twidth} and $_->{theight});
		}
}

######Выключение сервера базы
sub shutdown_server {$_[0]->{connection}->admin->run_command({'shutdown' => 1});} 

'nyak-nyak';