package SimpleCtemplate;
# Простой и быстрый шаблонизатор. Шаблоны компилируются в перлокод и кешируются в виде методов обьекта-шаблонизатора

use strict;
use Encode; 
use utf8;
use Data::Dumper;

#<var $var> - вывод переменной
# $var - перемерная, изменяется внутри loop,  %var - глобальная переменная, не изменется внутри loop
#<if УСЛОВИЕ> html контент</else/>(опционально) html контент </if> - условие
#<loop $hashref> вывод данных используя переменные </loop> - цикл
#<aloop $arrayhref> вывод данных используя переменные </loop> - цикл перебора массива. Текущее значение находится в $_
#<perleval perl_код  /> - выполнение кода
#<include %TMPLDIR%/head.tpl> подгрузка кода из другого файла

sub new {
	my $self = $_[1]? $_[1] : {};

	$self->{global}={} unless $self->{global};
	
	bless $self;
	
	local $_;
	
	if(${$self}{tmpl_dir}){ #подгружаем шаблоны из папки
	
	no strict 'refs';
	
	for( glob(${$self}{tmpl_dir}.'*.tpl') ){
		m|[^A-z]([A-z_-]*?).tpl$|;
		*{$1}=$self->compile($_);
	}

	use strict;
}

return $self; }
#######################################################################

sub load { #компилирует шаблон из кода/файла и создает метод обьекта. (код/путь к файлу ; имя метода, необязательно, если загружается из файла )
	my ($self,$code,$name)=@_; 
	
	if(!$name && -e $code){$code=~m|[^A-z]([A-z_-]*?).tpl$|; $name=$1;}
	die "SimpleCtemplate->load: You must define method name!" unless ($name);

	no strict 'refs';
	*{$name}=$self->compile($code);
	use strict;
return 1;
}

###########################################
sub compile {# (код/путь к файлу)= ссылка на скомпилированный в функцию шаблон
	my ($self,$code)=@_; 
	my $filename=' ';
	
	if(-e $code){ #можно и из файла грузить
		$filename.=$code;
		open my $tmlf,'<',$code;
		$code=join '',<$tmlf>;
		close $tmlf;
		}
###
	while($code=~m/(<include .*?>)/g){ # подгрузка шаблонов
		my $incname=$1;
		my $inctext =$incname;
		$incname=~s/%TMPLDIR%/${$self}{tmpl_dir}/;
		$incname=~m/<include (.*?)>/;
		open my $tmlf,'<',$1;
		my $inccode = join '',<$tmlf>;
		close $tmlf;
		$code=~s/$inctext/$inccode/g;
	}
 
##Обработка
	$code=~s/<!--.*?-->//sg; #комментарий 
	$code=~s/'/\\'/g;#экранируем кавычки
	$code=~s/([^\\])\$([_A-z]+)/$1\$vars{$2}/g; #имена переменны берем только из защищенного массива
	$code=~s/([^\\])%([_A-z]+)/$1\$global{$2}/g; # или глобального массива # который тоже защищен и существет только внутри метода-шаблона
	$code=~s/<var +(.*?)>/'.$1.'/g;#добавляем переменные
	$code=~s|<loop +(.*?)>|'; for(\@{$1}){my \%vars=%{\$_};\$text.='|g;#циклы
	$code=~s|<aloop +(.*?)>|'; for(\@{$1}){\$vars{_}=\$_;\$text.='|g;
	$code=~s^</loop>^'}; \$text.='^g; 
	$code=~s|<if +(.*?)>|'; if($1){\$text.='|g; #условия
	$code=~s|</else/>|';}else{ \$text.='|g; 
	$code=~s|</if>|';}; \$text.='|g; 
	$code=~s|<perleval +(.*?)/>|'; $1 ;\$text.='|sg; #выполнение кода
##Компилируем в анонимную функцию
my $sub;
	eval q |
	$sub = sub{
	my ($self,$vars,$global)=@_;
	my (%vars,%global,$k,$v);
	%vars=%{$vars} if($vars);
	%global=%{$self->{global}};
	if($global){$global{$k}=$v while(($k,$v)=each(%{$global}));};
	my $text; 
	$text='|.$code.q|'; 
	return encode('utf8',$text);};|;

	if($@){
		print "- Can't compile template$filename - $@\n";
		$sub = sub{my ($self,$vars)=@_; Dumper($vars)};
		print "$filename - Data::Dumper loaded!\n";
	};

	return $sub;
}
##########################################
our $AUTOLOAD;
sub AUTOLOAD {
	my ($self,$vars)=@_; 
	print "Undefined method $AUTOLOAD ! Data::Dumper loaded!\n";
	Dumper($vars)
}
'nyak-nyak';