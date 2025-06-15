#!/usr/bin/perl
use strict;
use Encode;
use utf8;
use FCGI;
use CGI;
use lib '.';
use FCGI::ProcManager;
use Benchmark qw(:all) ;
use Image::Size;

BEGIN {require 'config.pl'; }
BEGIN {require 'pedalutils.pl'; }

print "Ochoba loaded!\n";



#perl scriptname.pl - запуск в обычном режиме
#perl scriptname.pl d - демонизация
#perl scriptname.pl d количество_ворекров - демонизация, запуск заданного числа воркеров
my $proc_manager; 
if($ARGV[0]=~/d/i){ 
	unless(int($ARGV[1])){use POSIX qw(setsid); fork && exit; setsid;}
	else {
	$proc_manager = FCGI::ProcManager->new({ n_processes => int($ARGV[1]), die_timeout => 3 });
	}
}
my $socket = FCGI::OpenSocket(':9000', 10);
my $request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV, $socket);

$proc_manager->pm_manage() if($proc_manager);


###### Загружаем настройки ####################################
my (%GLOBALSETTINGS,%SECTIONS);
%GLOBALSETTINGS=%{GLOBAL_SETTINGS()};
%SECTIONS=%{GET_SECTIONS()};
$SECTIONS{$_}{SECTION}=$_ for(keys %SECTIONS);
$GLOBALSETTINGS{SECTIONS}=[keys %SECTIONS];

###### Загружаем  модули ######################################

use BoardDB; #БД
my  $db = BoardDB->new({boards=>$GLOBALSETTINGS{SECTIONS}, datestyle=>'%s %02d %s %04d %02d:%02d:%02d'});



use Cache::Memcached::Fast; #Мемкеш
my  $mem  =  Cache::Memcached::Fast->new({servers  => ['127.0.0.1:11211']});

use RealplexorApi; # Сomet сервер
$_= $^O=~/win/i ? '192.168.21.135' : '127.0.0.1'; # мы на сервере или на локалочке? # костыли-костылики
my $rp = RealplexorApi->new({login => undef, password=>'', host=>$_ ,port=>10010});


 
 


use BoardCache; # Кеширование
my $cache = BoardCache->new({
	db => $db,
	mem => $mem,
	extpaths =>{html => 'res',jpg => 'src',jpeg => 'src',gif => 'src',png => 'src'},
	SECTIONS => \%SECTIONS
});

our $query;
my $SECTION;
################################################################################


my $kostyl;
if($^O=~/win/i){$kostyl='FCGI::accept() >= 0';}else{$kostyl='$request ->Accept() >= 0';} #СПЕРМОКОСТЫЛЬ! #потом убрать...

while(eval $kostyl) { 
#my $SECTIONS{$SECTION}{TPL}=SimpleCtemplate->new({tmpl_dir =>'templates/',global=>{}});
eval { # ловим ошибки
###AntiDDOS
	$_=$mem->get('addos'.$ENV{REMOTE_ADDR});
	$_++;
	if($_>($GLOBALSETTINGS{ANTIDDOS_RCOUNT}+2)){$mem->set('addos'.$ENV{REMOTE_ADDR},9000);  next; } #тут код перманентного бана
	if($_>$GLOBALSETTINGS{ANTIDDOS_RCOUNT}){ print $query->redirect('/tomanyrequests.html'); $mem->set('addos'.$ENV{REMOTE_ADDR},$_,10); next; } #предупреждаем
	$mem->set('addos'.$ENV{REMOTE_ADDR},$_,10); 


### Получаем данные
	CGI->_reset_globals;
	$query = CGI->new;

###Распределитель##########
	unless($ENV{REQUEST_URI}=~m$/([^/]*?)/(.*?).((f?pl)|(memhtml))$){print $query->redirect('/404.html'); next};

	unless($SECTIONS{$1}){print $query->redirect('/404.html'); next}; #Нет раздела? 404!
	$SECTION=$1;

##Если у нас запросили сборку кеша
	if($3 eq 'memhtml'){
		unless($2=~m/^([0-9]*)$/){print $query->redirect('/404.html'); next}
		print $query->redirect('/404.html') unless($cache->page($SECTION,$1));
		next;
	}

	#if($2 eq 'index' or $2 eq 'wakaba'){ 
	#	unless($query->param('task')) {print $query->redirect('/404.html'); next} 
	#	$SECTIONS{$SECTION}{CONTROLLER}=$query->param('task');
	#} else {$SECTIONS{$SECTION}{CONTROLLER}=$2;}
	
	$SECTIONS{$SECTION}{CONTROLLER}=$2;
############################
#А теперь будем выбирать как запрос обработать
#Админка
if($SECTIONS{$SECTION}{CONTROLLER} eq 'adminlogin'){
#http://localhost/test/adminlogin.fpl?modpassword=
	if($query->param('modpassword') eq $GLOBALSETTINGS{MODER}){
		my $cookie;
		$cookie.=int(rand 9) for(1..5);
		$mem->set('admin'.$cookie,$ENV{REMOTE_ADDR});
		make_http_header({ochobaadmin =>$cookie});
		print 'ok';
		next;
		}
	make_error('Authorization error');
}
elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'admin'){# авторизация
	next unless check_admin(); 
	admin_controller();
next;}
elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'rebuild3745'){ # ребилд кешей
	my @threads=$db->{dbs}{$SECTION}{threads}->query({},{sort_by=>{ lasthit => -1}})->all;
	$cache->build_thread($SECTION,$_->{_id}) for(@threads);
	$cache->drop($SECTION);
	make_http_header(); print 'Done!';
next;}
elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'delete'){###Удаление постов###

	my $password=$query->param("password");
	make_error($SECTIONS{$SECTION}{LANG}{NO_PASSWORD}) unless($password);
	  
	my $fileonly=$query->param("fileonly");
	my @posts=$query->param("delete");
	  
	next if(scalar(@posts)>30);
	  
	delete_posts($SECTION,$password,$fileonly,@posts);
next;}
elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'post'){###Постинг###

	my $data;
		$data->{parent} = $query->param('parent');
		$data->{name} = $query->param('name');
		$data->{subject} = $query->param('subject');
		$data->{email} = $query->param('email');
		$data->{comment} = $query->param('comment');
		$data->{files} = [];
		
	
		my @files=$query->upload('file');
		@{$data->{files}}=splice(@files,0,$SECTIONS{$SECTION}{UPFILES});

		
	$data->{youtube} =$query->param('youtube');
	$data->{captcha} =$query->param('captcha');
	$data->{password} =$query->param('password');

	post($SECTION,$data);

next;}
elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'captcha'){###Капча###

	next unless($SECTIONS{$SECTION}{ENABLE_CAPTCHA});

	my $acap=$mem->get_multi('cadapt'.$ENV{REMOTE_ADDR},'clast'.$ENV{REMOTE_ADDR});
	unless(!$acap->{'cadapt'.$ENV{REMOTE_ADDR}} or $acap->{'clast'.$ENV{REMOTE_ADDR}}){
		print $query->redirect('/nocap.gif');
		next;
	};
	

	my($hash,$word);
	unless($hash=$mem->get('captcha'.$ENV{REMOTE_ADDR})){
		($hash,$word)=create_captcha($SECTIONS{$SECTION}{CAP_FONT},$SECTIONS{$SECTION}{CAP_WORDS});
		$mem->set_multi(['captcha'.$ENV{REMOTE_ADDR},$hash,3600],['captchahash'.$hash,$word,3600]);
	}

	print $query->redirect('/captchas/'.$hash.'.png');


	unless($mem->get('captchadrop')){ #  удаляем устаревшие капчи
		$cache->captcha_clear();
		$mem->set('captchadrop',1,3600*48);
	}

next;}
elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'search'){ #Поиск
	make_error($SECTIONS{$SECTION}{LANG}{SEARCH_TOO_FAST}) if($mem->get('search'.$ENV{REMOTE_ADDR}));
	
	$mem->set('search'.$ENV{REMOTE_ADDR},1,$GLOBALSETTINGS{SEARCH_TIMEOUT});
	
	search($SECTION,$query->param('search'));
	next;
}
#elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'post') {

#next;}
#elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'post') {

#next;}
#elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'post') {

#next;}
#elsif($SECTIONS{$SECTION}{CONTROLLER} eq 'post') {

#next;}
else{ #я вас не знаю
#print $query->redirect('/404.html'); next; #идите нахуй

	make_http_header();
	my ($k,$v);
	print "$k - $v <br/>\n" while(($k,$v)=each(%ENV));
}

#########################################################################
}; if ($@){ make_http_header(); print $@;};  # если словили ошибку - выводим
####конец цикла
};

print "end!\n";  # при нормальной работе скрипта этого мы никогда не увидим

################################################# 
###### Поиск #####
sub search {
	my ($SECTION,$search)=@_;
	make_error($SECTIONS{$SECTION}{LANG}{HACK_TRY}) if($ENV{REQUEST_METHOD} ne 'POST' and $search);
	Encode::_utf8_on($search);
	
	make_error($SECTIONS{$SECTION}{LANG}{SEARCH_TOO_LONG}) if(length($search)>35);
	$search=~s/[^A-zА-я ]//g;
	
	local $_=qr/$search(?!=[^<]*>)/i;
	
	make_http_header();
	print $SECTIONS{$SECTION}{TPL}->search({
		posts=>[$db->{dbs}{$SECTION}{posts}->find({ comment => $_ },{sort_by=>{_id=>-1}, limit => 50})->all],
		search => $search,
		
		},$SECTIONS{$SECTION});
	
}
################################################# 
###### Постинг #####
sub post{
	my ($SECTION,$data)=@_;
	Encode::_utf8_on($_) for %{$data};

	
	$ENV{REMOTE_ADDR}=$ENV{HTTP_X_FORWARDED_FOR}.'proxyfied' if($ENV{HTTP_X_FORWARDED_FOR});
#Проверяем данные
	$_=check_admin();
	make_error($SECTIONS{$SECTION}{LANG}{NO_REPLIES}) unless($SECTIONS{$SECTION}{REPLIES} or $_); #нельзя постить если раздел закрытый
	make_error($SECTIONS{$SECTION}{LANG}{NO_THREADS}) unless($SECTIONS{$SECTION}{THREADS} or $_); #нельзя создавать треды, если это отключено
	
	
	make_error($SECTIONS{$SECTION}{LANG}{NO_FILES}) if(!$SECTIONS{$SECTION}{UPFILES} and @{$data->{files}}); # проверка на файлы
	
	make_error($SECTIONS{$SECTION}{LANG}{UNUSUAL}) if($data->{parent}=~/[^0-9]/ or $data->{name}=~/[\n\r]/ or $data->{email}=~/[\n\r]/ or $data->{subject}=~/[\n\r]/ or length($data->{parent})>15); #проверка на недопустимые символы
	
	
	
	######ня
	
	
	make_error($SECTIONS{$SECTION}{LANG}{TOOLONG}) if(
	length($data->{email})>$SECTIONS{$SECTION}{MAX_FIELD_LENGTH} 
	or length($data->{subject})>$SECTIONS{$SECTION}{MAX_FIELD_LENGTH}
	or length($data->{name})>$SECTIONS{$SECTION}{MAX_FIELD_LENGTH}); #слишком длинное поле
	
	make_error($SECTIONS{$SECTION}{LANG}{TOOLONG_MSG}) if(length($data->{comment})>$SECTIONS{$SECTION}{MAX_COMMENT_LENGTH}); #слишком длинное сообщение
	
	
	#поверка капчи
	if($SECTIONS{$SECTION}{ENABLE_CAPTCHA} and !check_admin()){
	
		my $acap=$mem->get_multi('cadapt'.$ENV{REMOTE_ADDR},'clast'.$ENV{REMOTE_ADDR});
		$mem->delete('cadapt'.$ENV{REMOTE_ADDR}) if($acap->{'clast'.$ENV{REMOTE_ADDR}});
		
		if(!$acap->{'cadapt'.$ENV{REMOTE_ADDR}} or $acap->{'clast'.$ENV{REMOTE_ADDR}}){
			make_error($SECTIONS{$SECTION}{LANG}{WRONG_CAPTCHA}) unless ($_=$mem->get('captchahash'.$mem->get('captcha'.$ENV{REMOTE_ADDR})));
			Encode::_utf8_on($_);
			make_error($SECTIONS{$SECTION}{LANG}{WRONG_CAPTCHA}) unless($data->{captcha}=~m/$_/i);
		}
		
		$mem->set_multi(['cadapt'.$ENV{REMOTE_ADDR},1,86400],['clast'.$ENV{REMOTE_ADDR},1,$GLOBALSETTINGS{ACAPTCAHA_TIMEOUT}]);  #отключаем капчу
	}

	delete $data->{captcha};
	make_error($SECTIONS{$SECTION}{LANG}{BANNED}.$_->{reason}) if($_=$db->{connection}->settings->bans->find_one({_id => $ENV{REMOTE_ADDR}})); #бан
	
	make_error($SECTIONS{$SECTION}{LANG}{THREAD_NOT_EXISTS}) if($data->{parent} and !$db->checkThread($SECTION,$data->{parent})); #поверка на сущестование треда
	
	$data->{youtube}='' unless ($SECTIONS{$SECTION}{YOUTUBE});
	$data->{youtube}=$data->{youtube}=~m%(http://)?.{0,5}?youtube.{2,5}?/.{0,6}?\?v=([A-z0-9_-]*).*?%i 
? $2 : $data->{youtube}=~m%([A-z0-9_-]{5,20})%i ? $1 : ''; #получаем id видео
	
	$data->{files}=[] if($data->{youtube}); #если есть видео файлы не загружаются
	
#1 - слишком большой файл
#2 - нет файла
#3 - невозможно создать превью
#4 - формат не поддерживается
#5 - слишком большие размеры картинки
	
	my ($tmpfilename,@errors,@files);
	for(@{$data->{files}}){
		$tmpfilename=scalar $_;
		$_=$cache->upload_file($SECTION,$_);
		if($_==1){push @errors,$tmpfilename.' - '.$SECTIONS{$SECTION}{LANG}{FILE_TOO_BIG}}
		elsif($_==2){push @errors,$tmpfilename.' - '.$SECTIONS{$SECTION}{LANG}{NO_FILE}}
		elsif($_==3){push @errors,$tmpfilename.' - '.$SECTIONS{$SECTION}{LANG}{CANT_CREATE_THUMBNAIL}}
		elsif($_==4){push @errors,$tmpfilename.' - '.$SECTIONS{$SECTION}{LANG}{UNSUPPORTED_FORMAT}}
		elsif($_==5){push @errors,$tmpfilename.' - '.$SECTIONS{$SECTION}{LANG}{TOO_BIG_RES}}
		else{push @files,$_;}
	}
	
	make_error($SECTIONS{$SECTION}{LANG}{NO_MSG}.'<br/>'.join('<br/>',@errors)) unless($data->{comment}=~/[А-яA-z0-9]/ or @files or $data->{youtube}); # пустое сообщение
	$data->{files}=\@files;
	 
	make_error($SECTIONS{$SECTION}{LANG}{THREADS_WITH_FILES}) if($SECTIONS{$SECTION}{THREADS_WITH_FILES} and !$data->{parent} and !@files); #если нельзя создавать треды без файла
	
	
##### Обработка текста #######
	#unless(check_admin()){
		filter_html(\$data->{email});
		filter_html(\$data->{subject});
		filter_html(\$data->{name});
		filter_html(\$data->{comment});
	#}
	##
	$data->{name}=$SECTIONS{$SECTION}{DEFAULT_NAME} if(!$data->{name} or $SECTIONS{$SECTION}{FORCED_ANON});
	
	##ссылки на посты
	my $i;
	while($data->{comment}=~m|&gt;&gt;(/?([A-z]*)/)?([0-9]{1,15})|g){
		my ($fsect,$sect,$num)=($1,lc($2),$3); $i++;
		last if($i > 15);

		unless($sect){$sect=$SECTION}else{
			next unless($db->{dbs}{$sect}{posts});
		}
		next unless($_ = $db->{dbs}{$sect}{posts}->find_one({_id =>int $num }));
		$_->{parent}=$_->{_id} unless($_->{parent});
		
		$sect.='/'; #|(?:>>)
		$data->{comment}=~s%(?<!">)(?:&gt;&gt;)$fsect$num(?![0-9])%$1<a href="/${sect}res/$_->{parent}.html#$_->{_id}" onclick="highlight($_->{_id})">&gt;&gt;$fsect$_->{_id}<\/a>%;
	}
	
	$data->{comment}=do_mark($SECTION,$data->{comment});
	($data->{name},$data->{trip})=process_tripcode($data->{name},$SECTIONS{$SECTION}{UNIQUE_IDS} ? $ENV{REMOTE_ADDR} : '');
	
##########
	$mem->delete('captcha'.$ENV{REMOTE_ADDR}); #сбрасываем капчу
	$data->{ip}=$ENV{REMOTE_ADDR}; #сохраняем ip

	
	
	#### Пекацефальные фильтры
	
	$_=$data->{name}; s/[^А-яA-z]//g;
	make_error(':3') if (m/^(Н|H)як(а|a)/i and $ENV{REMOTE_ADDR} ne '78.60.110.240');
	
	
	if($db->{connection}->settings->roosters->find_one({_id => $ENV{REMOTE_ADDR}})){
		$data->{name}='Главпетух-митолер';
		$data->{comment}=~s/ [^ ]*? / ко-ко-ко /gi;
		$data->{password}='pe2shock';
		$data->{subject}='КУДАХ-ТАХ-ТАХ! КУКАРЕКУ!';
		$data->{files}=[{
			filepath=>'src/pe2shock.png',
			thumbnail=>'src/pe2shock.png',
			filename=> 'Мое фото.кукареку',
			twidth => 200,
			theight => 200,
		}];
	};
	
	
	
	
	
	
	
	
##### Cоздаем пост ########
	my $postid=$db->addPost($SECTION,$data); 
	if($data->{parent}){
		$rp->send_data([$SECTION.'_'.$data->{parent}],{%{$data}, ip => undef , password => undef});
	  
		$db->postToThread($SECTION,$data->{parent},[$postid], $data->{email}=~/sage/i ? 0 : $SECTIONS{$SECTION}{ BUMPLIMIT} );

		$cache->drop($SECTION); # сбрасываем кеш страниц
	  
		make_error($SECTIONS{$SECTION}{LANG}{UPLOADING_ERROR}.'<br/>'.join('<br/>',@errors),
		$cache->build_thread($SECTION, $data->{parent}).'#'.$postid) if(@errors);# выводим ошибки при загрузке файлов
	  
		print $query->redirect($cache->build_thread($SECTION, $data->{parent}).'#'.$postid);
	}
	else
	{
		$db->setThread($SECTION,{posts=>[$postid], _id=> $postid , lasthit => time, closed => 0, sticked => 0 });
		
		$db->clearPage($SECTION,$SECTIONS{$SECTION}{MAX_PAGES},$SECTIONS{$SECTION}{THREADS_PER_PAGE}) if($SECTIONS{$SECTION}{MAX_PAGES});
		
		$cache->drop($SECTION); # сбрасываем кеш страниц
	  
		make_error($SECTIONS{$SECTION}{LANG}{UPLOADING_ERROR}.'<br/>'.join('<br/>',@errors),
		$cache->build_thread($SECTION, $postid)) if(@errors); # выводим ошибки при загрузке файлов
	  
		print $query->redirect($cache->build_thread($SECTION, $postid));
	}
	
	return 1;
}


##############################################################################
#### Удаление постов
sub delete_posts{
	my($SECTION,$password,$fileonly,@posts)=@_;
	Encode::_utf8_on($password);
	my (@errors,%threads,$post);
	
	my $admin=check_admin();
	$password=1 if $admin;
	
	for(@posts){
		$post=$db->{dbs}{$SECTION}{posts}->find_one({_id =>int $_ });
		unless($post){push @errors,$_.' - '.$SECTIONS{$SECTION}{LANG}{NO_POST}; next}
		unless($password eq $post->{password} or $admin){push @errors,$_.' - '.$SECTIONS{$SECTION}{LANG}{WRONG_PASSWORD}; next}
	
		if($fileonly){
			$db->deleteFiles($SECTION,$post->{files}); #удаляем файлы поста
			if($post->{parent}){$threads{$post->{parent}}=1} else {$threads{$post->{_id}}=1}
			$post->{files}=[];
			$db->setPost($SECTION,$post);
		}
		else
		{
			unless($post->{parent}){
				$db->delThread($SECTION,$post->{_id})
			}
			else
			{
				$db->delFromThread($SECTION,$post->{parent},[int $post->{_id}]); #удаляем пост из треда
				$db->{dbs}{$SECTION}{posts}->remove({'_id' =>int $post->{_id}}); #удаляем из базы
				$db->deleteFiles($SECTION,$post->{files}); #удаляем файлы поста
				$threads{$post->{parent}}=1;
			}
		}
	}

	if(scalar(@errors) < scalar(@posts)){
		unless($fileonly){$db->unBump($SECTION,$_) for(keys %threads);}
		$cache->build_thread($SECTION, $_) for(keys %threads); 
		$cache->idrop($SECTION);
	}
	
	make_error($SECTIONS{$SECTION}{LANG}{DELETING_ERROR}.'<br/>'.join('<br/>',@errors),
	'/'.$SECTION.'/0.memhtml') if(@errors); 
	  
	print $query->redirect('/'.$SECTION.'/0.memhtml');
}
				


##################### Админка ##############################

sub check_admin{
	return 1 if($mem->get('admin'.$query->cookie('ochobaadmin')) eq $ENV{REMOTE_ADDR});
}

#
sub admin_controller{
	$mem->set('addos'.$ENV{REMOTE_ADDR},0);
	my $action=$query->param('do');
	
	if($action eq 'bans'){
		make_http_header();
		print $SECTIONS{$SECTION}{TPL}->bans({
			banned => [$db->{connection}->settings->bans->find->all],
		},$SECTIONS{$SECTION});
	}
	elsif($action eq 'posts'){ 
		make_http_header();
	
		$_ = {};
		$_ = { ip =>$db->{dbs}{$SECTION}{posts}->find_one({_id => int $query->param('post')})->{ip}} if($query->param('post'));
		$_ = { ip =>$query->param('ip')} if($query->param('ip'));
	
	print $SECTIONS{$SECTION}{TPL}->plist({
		posts=>[$db->{dbs}{$SECTION}{posts}->query($_,{limit=>500, skip => 500*($query->param('page')), sort_by=>{ _id => -1}})->all],
		
		ip => $_->{ip},
		pages => [0..($db->{dbs}{$SECTION}{posts}->count($_)/500)],
		},$SECTIONS{$SECTION});
		
	}
	elsif($action eq 'stick'){
		next unless($db->{dbs}{$SECTION}{threads}->find_one({_id => int $query->param('thread')}));
		
		$db->stickThread($SECTION,$query->param('thread'));
		$cache->build_thread($SECTION,$query->param('thread'));
		$cache->idrop($SECTION);
		
		print $query->redirect($ENV{HTTP_REFERER});
	}
	elsif($action eq 'close'){
		next unless($db->{dbs}{$SECTION}{threads}->find_one({_id => int $query->param('thread')}));
		
		$db->closeThread($SECTION,$query->param('thread'));
		$cache->build_thread($SECTION,$query->param('thread'));
		$cache->idrop($SECTION);
		
		print $query->redirect($ENV{HTTP_REFERER});
	}
	#elsif($action eq ''){
	
	#}
	#elsif($action eq ''){
		
	#}
	#elsif($action eq ''){
	
	#}	
	elsif($action eq 'ban'){
		my $ip=$query->param('ip');
	#  my $expires=$query->param('expires');
		my $reason=$query->param('reason');
			$db->{connection}->settings->bans->save({_id =>$ip,
			#expires=>$expires,
			reason =>$reason});
		print $query->redirect('admin.fpl?do=bans');
	}
	elsif($action eq 'unban'){
		$db->{connection}->settings->bans->remove({_id =>$query->param('ip')});
		print $query->redirect('admin.fpl?do=bans');
	}
	elsif($action eq 'banpost'){
	my $reason=$query->param('reason');
		$db->{connection}->settings->bans->save({_id =>$db->{dbs}{$SECTION}{posts}->find_one({_id=>int $query->param('post')})->{ip},
		#expires=>$expires,
		reason =>$reason});
		print $query->redirect('admin.fpl?do=bans');
	}
	elsif($action eq 'pe2shock'){
		$db->{connection}->settings->roosters->save({_id =>$db->{dbs}{$SECTION}{posts}->find_one({_id=>int $query->param('post')})->{ip}});
		print $query->redirect($ENV{HTTP_REFERER});
	}
	elsif($action eq 'posan'){
		$db->{connection}->settings->roosters->remove({_id =>$db->{dbs}{$SECTION}{posts}->find_one({_id=>int $query->param('post')})->{ip}});
		print $query->redirect($ENV{HTTP_REFERER});
	}
	else
	{
		print $SECTIONS{$SECTION}{TPL}->head({},$SECTIONS{$SECTION});
		print $SECTIONS{$SECTION}{TPL}->admin_head({},$SECTIONS{$SECTION});
		print $SECTIONS{$SECTION}{TPL}->foot({},$SECTIONS{$SECTION});
	}
	
}




##################################################
sub make_http_header{
	my ($cookies)=@_;
	
	if($cookies){
		my ($name,$value);
		my @days=qw(Sun Mon Tue Wed Thu Fri Sat);
		my @months=qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
		my ($sec,$min,$hour,$mday,$mon,$year,$wday)=gmtime(time+14*24*3600);
		my $date= sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",$days[$wday],$mday,$months[$mon],$year+1900,$hour,$min,$sec);
		print "Set-Cookie: $name=$value; path=/; expires=$date;\n" while(($name,$value)=each %{$cookies});
	}
	
	print "Content-Type: text/html\n\n";
}

sub make_error
{
	my ($error,$link)=@_;
	print "Content-Type: text/html\n\n";
	print $SECTIONS{$SECTION}{TPL}->err({
		error => $error,
		link => $link,
		
		},$SECTIONS{$SECTION});
		
	next;
}
######################
sub process_tripcode
{
	my ($name,$ip)=@_;
	my $tripkey=$GLOBALSETTINGS{TRIPKEY};
	my $secret=$GLOBALSETTINGS{SECRET};
	
	$ip=$tripkey.$tripkey.$tripkey.hide_data($ip,6,"trip",$secret) if($ip);
	
	if($name=~/^(.*?)((?<!&)#|\Q$tripkey\E)(.*)$/)
	{
		my ($namepart,$marker,$trippart)=($1,$2,$3);
		my $trip;
		
		if($secret and $trippart=~s/(?:\Q$marker\E)(?<!&#)(?:\Q$marker\E)*(.*)$//) # do we want secure trips, and is there one?
		{
			$trip=$tripkey.$tripkey.hide_data($1,6,"trip",$secret);
			return ($namepart,$trip.$ip) unless($trippart); # return directly if there's no normal tripcode
		}

		# 2ch trips are processed as Shift_JIS whenever possible
		$trippart=encode("Shift_JIS",$trippart,0x0200);
		
		my $salt=substr($trippart.'H..',1,2);
		$salt=~s/[^\.-z]/./g;
		$salt=~tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/; 
		$trip=$tripkey.(substr crypt($trippart,$salt),-10).$trip;

		return ($namepart,$trip.$ip);
	}
return ($name,$ip);
}
###############################################################
sub do_mark{
	my ($SECTION,$in)=@_;

	my($regexp,$out,@unclosed); # обработка ббкодов 
	my @keys=keys(%{$SECTIONS{$SECTION}{BBCODE}}); $_= shift @keys; $regexp.=$_.'|' for(@keys); $regexp.=$_;
	my $maxcount=30; #максимальное количество тегов  x2

	while($in=~s+^(.*?)\[(/?)($regexp)\]++s){
		$out.=$1;
		if($2){if($3 eq $unclosed[-1]){$out.=$SECTIONS{$SECTION}{BBCODE}{$3}[1]; pop @unclosed }else{$out.="[$2$3]";};}
		else{push @unclosed, $3; $out.=$SECTIONS{$SECTION}{BBCODE}{$3}[0];}
	
		$maxcount--;
		last unless($maxcount);
	} $out.=$in; $out.=$SECTIONS{$SECTION}{BBCODE}{$_}[1] while($_ = pop @unclosed);

  ##вакабамарк из вакабы
    $out=~s!(\r?\n|^)(&gt;.*?)(?=$|\r?\n)!$1<span class="unkfunc">$2</span>$3!g;
	$out=~s/\r?\n/<br\/>\n/g;

	$out=~s{ (?<![0-9a-zA-Z\*_\x80-\x9f\xe0-\xfc]) (\*\*) (?![<>\s\*_]) ([^<>]+?) (?<![<>\s\*_\x80-\x9f\xe0-\xfc]) \1 (?![0-9a-zA-Z\*_]) }{<strong>$2</strong>}gx;
	# do <em>
	$out=~s{ (?<![0-9a-zA-Z\*_\x80-\x9f\xe0-\xfc]) (\*) (?![<>\s\*_]) ([^<>]+?) (?<![<>\s\*_\x80-\x9f\xe0-\xfc]) \1 (?![0-9a-zA-Z\*_]) }{<em>$2</em>}gx;
	#Spoilers
	$out=~s{ (?<![0-9a-zA-Z\*_\x80-\x9f\xe0-\xfc]) (\%\%) (?![<>\s\*_]) ([^<>]+?) (?<![<>\s\*_\x80-\x9f\xe0-\xfc]) \1 (?![0-9a-zA-Z\*_]) }{<span class="spoiler">$2</span>}gx;
	#Del
	$out=~s{ (?<![0-9a-zA-Z\*_\x80-\x9f\xe0-\xfc]) (\^) (?![<>\s\*_]) ([^<>]+?) (?<![<>\s\*_\x80-\x9f\xe0-\xfc]) \1 (?![0-9a-zA-Z\*_]) }{<del>$2<del>}gx;
	#^H
	$_=qr/(?:&#?[0-9a-zA-Z]+;|[^&<>])(?<!\^H)(??{$_})?\^H/;
	$out=~s{($_)}{"<del>".(substr $1,0,(length $1)/3)."</del>"}gex;
	#ссылки
    $out=~s^(http://|https://|ftp://|mailto:|news:|irc:|xmpp:|magnet:|skype:)([-A-zА-я0-9_?/:=+%&.@]+)^<a href="$1$2">$1$2</a>^g;
	
	return $out;
}
