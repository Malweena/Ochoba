package BoardCache;

use strict;
use utf8;
use Encode;
use Fcntl qw/:flock/;
use File::Copy;
use Image::Size;

##############
sub new { 
	my $self = $_[1];
	die 'BoardCache: Undefined db or mem or SECTIONS' unless($self->{db} and $self->{mem} and $self->{SECTIONS});
	
	$self->{memext}='memhtml' unless($self->{memext});
	$self->{thrext}='html' unless($self->{thrext});
	$self->{extpaths}={} unless($self->{extpaths}); 
	$self->{threadpath}= 'res' unless($self->{threadpath});
	$self->{thumbpath}='thumb' unless($self->{thumbpath});
	
	$self->{db}->{thrext}=$self->{thrext};
	$self->{db}->{threadpath}=$self->{threadpath};
	
	
	# создаем структуру директорий если ее не существует
	foreach my $cpath(keys %{$self->{SECTIONS}}){ mkdir($cpath) unless(-d($cpath)); 
	
		mkdir("$cpath/$self->{thumbpath}") unless(-d("$cpath/$self->{thumbpath}"));
		mkdir("$cpath/$self->{threadpath}") unless(-d("$cpath/$self->{threadpath}"));
		
		for(values %{$self->{extpaths}}){mkdir("$cpath/$_") unless(-d("$cpath/$_"))}
	}
	bless $self;
	return $self; 
}
################################################

sub page{ #ребилд страницы
	my($self,$SECTION,$page)=@_;
	my $cacheadr="/$SECTION/$page.$self->{memext}";

	# С этим можно поэкспериментировать при больших нагрузках. Если пришел запрос, а в это время другой процесс пересобирает кеш, то отдаем страничку из второго кеша для бэкенда, чтоб лишний раз не запускать ребилд кеша. Но это влияет только при десятках-сотнях запросах в секунду и интенсивном постинге
#	if($self->{mem}->get('rebuilding'.$cacheadr)){ # ребилдом этого кеша уже занимается другой процесс
#		print "Content-Type: text/html\n\n";  # придеться немного поработать сервером для отдачи статики
#		print encode('utf8',$self->{mem}->get('forbackend'.$cacheadr));
#		return 1;
#	}
#	$self->{mem}->set('rebuilding'.$cacheadr,1,5); # а иначе сами займемся ребилдом
	
	my $pagescount = $self->{db}->countPages($SECTION,$self->{SECTIONS}{$SECTION}{THREADS_PER_PAGE});
	$self->{mem}->set('pagescount'.$SECTION,$pagescount);

	if($page>$pagescount){ # нет такой страницы
		$self->{mem}->delete('rebuilding'.$cacheadr);
		return;
	}
	
	# ребилдим
	  $_=scalar $self->{SECTIONS}{$SECTION}{TPL}->page({
		threads=>$self->{db}->getPage($SECTION,$page,$self->{SECTIONS}{$SECTION}{THREADS_PER_PAGE},$self->{SECTIONS}{$SECTION}{REPLIES_PER_THREAD}),
		
		pages=>[0...$pagescount],
		current=>$page
		},$self->{SECTIONS}{$SECTION});
	
	$self->{mem}->set_multi([$cacheadr,$_],['forbackend'.$cacheadr,$_]);
	$self->{mem}->delete('rebuilding'.$cacheadr);
	print "Content-Type: text/html\n\n";
	print $_; 
	
	return 1;
}

sub build_thread{ #ребилд треда
	my ($self,$SECTION,$thread)=@_;
	my $data=$self->{db}->getThread($SECTION,$thread);
	
	open my $fhandle,'>',"$SECTION/$self->{threadpath}/$thread.$self->{thrext}" or die 'BoardCache: Can`t open thread file!';
	flock($fhandle,LOCK_EX);
	binmode($fhandle);
	
	print $fhandle $self->{SECTIONS}{$SECTION}{TPL}->page({
		thread=>$thread,
		threads=>[$data],
		},{ %{$self->{SECTIONS}{$SECTION}}, thread=>$thread, %{$data}});
		
	close $fhandle;
		
	return "$self->{threadpath}/$thread.$self->{thrext}";
}

sub drop{ #сброс кеша страниц
	my ($self,$SECTION)=@_;
	
	return if($self->{mem}->get('lastcachedrop'.$SECTION)); # не сбрасываем кеши чаще, чем раз в секунду
	$self->{mem}->set('lastcachedrop'.$SECTION,1,1);
	
	my $pagescount=$self->{db}->countPages($SECTION,$self->{SECTIONS}{$SECTION}{THREADS_PER_PAGE});
	
	my $data;
	for(0..$pagescount){
		$data = $self->{mem}->get("/$SECTION/$_.$self->{memext}");
		$data = $self->{mem}->get("forbackend/$SECTION/$_.$self->{memext}")unless($data);
		$self->{mem}->set("/$SECTION/$_.$self->{memext}",$data,1);
	}  # кеши страниц умрут через секунду
	
	return 1;
}

sub idrop{ # немедленный сброс кешей
	my ($self,$SECTION)=@_;

	my $pagescount=$self->{db}->countPages($SECTION,$self->{SECTIONS}{$SECTION}{THREADS_PER_PAGE});
	$self->{mem}->delete("/$SECTION/$_.$self->{memext}") for(0..$pagescount);

	return 1;
}

sub captcha_clear{ #очистка устаревших капч
	my @captchas=glob('captchas/*.png');
	for(@captchas){unlink "captchas/$_.png" unless($_[0]->{mem}->get('captchahash'.$_));}
}

# Универсальный метод сохранения
sub save {
	my ($self,$cachepath,$file,$data,$path,$rw)=@_;
	Encode::_utf8_on($file);
	$file=~s|^.*?([^/\\]*)\.([A-z]*)$|$1|;
	my $ext=lc($2);
	
	$file=~s/[^А-яA-z0-9]//g;

	unless($path and -d("$cachepath/$path")){
		return unless($path=$self->{extpaths}{$ext});
	}

	if(!$rw and -e("$cachepath/$path/$file.$ext")){do{$file.=int(rand(9))}while(-e("$cachepath/$path/$file.$ext"));}

	open my $fhandle,'>',"$cachepath/$path/$file.$ext" or return;
	flock($fhandle,LOCK_EX);
	binmode($fhandle);
	if(ref($data) eq 'Fh' or ref($data) eq 'GLOB'){
	
		binmode($data);
		copy($data,$fhandle) or return;
		close $data;
		
	} else {print $fhandle $data;}
	
	close $fhandle;
	
	return "$path/$file.$ext";
}

#### Выгрузка файлов
sub upload_file{
	my ($self,$SECTION,$name,$fhandle)=@_;
	$fhandle=$name unless($fhandle);
	# Возвращает:
	#1 - слишком большой файл
	#2 - ошибка в процессе загрузки
	#3 - невозможно создать превью
	#4 - формат не поддерживается
	#5 - слишком большие размеры картинки
	# успешно - ссылка на хеш
	
	my $data={};
	$name= scalar($name);
	$name= decode('utf8',$name);
	$name=~s|^.*?([^/\\]{0,32})\.([A-z]*)$|$1|;
	my $ext=lc($2);
	$name=~s/[^A-zА-я0-9._-]//g;

	$name=time+int(rand(1000)) . int(rand 1000) if($self->{SECTIONS}{$SECTION}{RANDNAMES});

	return 2 unless($name and $ext); # пустое имя или расширение файла

	keys(%{$self->{SECTIONS}{$SECTION}{FILETYPES}});
	my ($k,$v);
	while(($k,$v)=each(%{$self->{SECTIONS}{$SECTION}{FILETYPES}})){
		next unless($ext=~m/^$k$/i);
		#######################
		my @stat=stat($fhandle);
		
		return 1 if($stat[7]>$self->{SECTIONS}{$SECTION}{MAX_FILESIZE}); 
		return 2 unless($stat[7]);
		
		$data->{size}=sprintf('%.2f',$stat[7]/1024);
	
		if(defined $v){
			$data->{thumbnail}=$v;
			#$data->{filepath}=$dcache->save($SECTION,$data->{filename},$fhandle,0,0); #сохраняем
				#сохраняем
			$name.=int(rand(9)) while(-e("$SECTION/$self->{extpaths}{$ext}/$name.$ext"));
				open my $fsave,'>',"$SECTION/$self->{extpaths}{$ext}/$name.$ext" or return 2;
				binmode($fsave); binmode($fhandle);
				copy($fhandle,$fsave) or return 2;
				close $fsave; close $fhandle;
				
			$data->{filename}=$name.'.'.$ext;
			$data->{filepath}="$self->{extpaths}{$ext}/$name.$ext";
			
		} # есть иконка для этого формата
		else
		{ #иначе пробуем ресайзить
			my ($width,$height)=imgsize($fhandle);
			return 3 unless($width and $height);
		
			#$data->{filepath}=$dcache->save($SECTION,$data->{filename},$fhandle,0,0); #сохраняем
			#сохраняем
			$name.=int(rand(9)) while(-e("$SECTION/$self->{extpaths}{$ext}/$name.$ext"));
				open my $fsave,'>',"$SECTION/$self->{extpaths}{$ext}/$name.$ext" or return 2;
				binmode($fsave); binmode($fhandle);
				copy($fhandle,$fsave) or return 2;
				close $fsave; close $fhandle;
				
			$data->{filename}=$name.'.'.$ext;
			$data->{filepath}="$self->{extpaths}{$ext}/$name.$ext";
			
			$data->{width}=$width;
			$data->{height}=$height;
		
			if($width>$self->{SECTIONS}{$SECTION}{AMAX_W} or $height>$self->{SECTIONS}{$SECTION}{AMAX_H})
			{unlink($SECTION.'/'.$data->{filepath}); return 5;}  # слишком большое разрешение
		 
			if($width>$self->{SECTIONS}{$SECTION}{MAX_W}){ #умный ресайзер
				$width=$self->{SECTIONS}{$SECTION}{MAX_W};
				$height=int(($self->{SECTIONS}{$SECTION}{MAX_W}*$data->{height})/$data->{width});
			};
			if($height>$self->{SECTIONS}{$SECTION}{MAX_H}){
				$height=$self->{SECTIONS}{$SECTION}{MAX_H};
				$width=int(($self->{SECTIONS}{$SECTION}{MAX_H}*$data->{width})/$data->{height});
			}
			$width=1 unless($width);
			$height=1 unless($height);
		
			$data->{twidth}=$width;
			$data->{theight}=$height;
		###
			my $thumbname=$data->{filepath};
		
			$thumbname=~s|^.*?([^/\\]*)\.([A-z]*)$|$1|;
		
			$data->{filepath}=~s/gif$/gif[0]/i;
			`convert -channel RGBA -background none -quality 100 -flatten -size ${width}x${height} -geometry ${width}x${height}!  $SECTION/$data->{filepath} $SECTION/$self->{thumbpath}/$thumbname.$ext`;
			$data->{filepath}=~s/\[0\]$//;
			
			if($?){unlink($SECTION.'/'.$data->{filepath}); return 3;}; #не могу отресайзить
			$data->{thumbnail}="$self->{thumbpath}/$thumbname.$ext";
		}
		return $data;
	};
	return 4;
}

'nyak-nyak';