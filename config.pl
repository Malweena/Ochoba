use utf8;
use Template;

my %SETTINGS;
$SETTINGS{CAP_FONT}='/home/admin/ochoba/captcha/DigitalStripCyrillic.ttf';
$SETTINGS{TPL}=Template->new({tmpl_dir =>'templates/'});
$SETTINGS{THREADS}=1;

$SETTINGS{TITLE} = 'Тире.ч - ';
$SETTINGS{ REPLIES } = 1;
$SETTINGS{ UPFILES } = 5;		# Разрешить добавление файлов
$SETTINGS{ THREADS_WITH_FILES } = 0; #создавать треды только с файлами
$SETTINGS{ MAX_FIELD_LENGTH } = 50;
$SETTINGS{ MAX_COMMENT_LENGTH }= 1024*20;

$SETTINGS{ BUMPLIMIT } = 500;

$SETTINGS{ THREADS_PER_PAGE } = 25;			# тредов на странице
$SETTINGS{ REPLIES_PER_THREAD } = 5;			# показывать на странице последних ответов из треда
$SETTINGS{ ENABLE_CAPTCHA } = 1;  #использовать капчу

$SETTINGS{ MAX_FILESIZE } = 1024*1024*9;

$SETTINGS{ RANDNAMES } = 1; # удалять имена файлов
$SETTINGS{ MAX_W } = 200; # уменьшать изображения -
$SETTINGS{ MAX_H } = 200; # - начиная с этого разрешения
$SETTINGS{ AMAX_W } = 10000;	# максимальная ширина
$SETTINGS{ AMAX_H } = 10000;	# максимальная длинна


$SETTINGS{ FORCED_ANON } = 0; #принудительная анонимность
$SETTINGS{ DEFAULT_NAME } = 'Аноним'; # Имя, если имя не задано или принудительная анонимность
$SETTINGS{ UNIQUE_IDS } = 0; #дополнительный трипкод - хеш из ip
$SETTINGS{ YOUTUBE } = 1; #постинг видео

$SETTINGS{ BBCODE } ={

sup		=> ['<sup>',					 '</sup>'],
sub		=> ['<sub>',					 '</sub>'],
big		=> ['<span style="font-size:36px;">', '</span>'],
small	=> ['<span style="font-size:8px;">', '</span>'],
center	=> ['<center>',					 '</div>'],
right	=> ['<div style="float:right">', '</center>'],
b		=> ['<strong>',				  '</strong>'],
unown	=> ['<h2>',						  '</h2>'],
ascii	=> ['<pre>',					 '</pre>'],
i		=> ['<em>',						  '</em>'],
code	=> ['<code>',					'</code>'],
s		=> ['<del>',					 '</del>'],
hide	=> ['<span class="hide">',		'</span>'],        
u		=> ['<span class="u">',			'</span>'],
o		=> ['<span class="o">',			'</span>'],
spoiler	=> ['<span class="spoiler">',	'</span>'],
#'0000FF' => ['<font color="#0000FF">',	'</font>'],
#'00FF00' => ['<font color="#00FF00">',	'</font>'],
#'FF0000' => ['<font color="#FF0000">',	'</font>'],
#'rghost' => [ q|<a onload="this.href = 'http'+'://plasmon.rghost.ru/'+$(this).html+'.image'; 
#$(this).html('<img 
#src=http:'+'//plasmon.rghost.ru/'.$(this).html.'.image" />')" >| , q|</a>|],
};


$SETTINGS{FILETYPES} = {
  png => undef,
  jpg => undef,
  jpeg => undef,
  gif => undef,
   # Audio files
	mp3 => 'icons/audio-mp3.png',
#	ogg => 'icons/audio-ogg.png',
#	aac => 'icons/audio-aac.png',
#	m4a => 'icons/audio-aac.png',
#	mpc => 'icons/audio-mpc.png',
#	mpp => 'icons/audio-mpp.png',
#	mod => 'icons/audio-mod.png',
#	it => 'icons/audio-it.png',
#	xm => 'icons/audio-xm.png',
#	fla => 'icons/audio-flac.png',
#	flac => 'icons/audio-flac.png',
#	sid => 'icons/audio-sid.png',
#	mo3 => 'icons/audio-mo3.png',
#	spc => 'icons/audio-spc.png',
#	nsf => 'icons/audio-nsf.png',
	# Archive files
#	zip => 'icons/archive-zip.png',
#	rar => 'icons/archive-rar.png',
#	lzh => 'icons/archive-lzh.png',
#	lha => 'icons/archive-lzh.png',
#	gz => 'icons/archive-gz.png',
#	bz2 => 'icons/archive-bz2.png',
#	'7z' => 'icons/archive-7z.png',
	# Other files
#	swf => 'icons/flash.png',
#	torrent => 'icons/torrent.png',
	# To stop Wakaba from renaming image files, put their names in here like this:
#	gif => '.',
#	jpg => '.',
#	png => '.',
};

$SETTINGS{CAP_WORDS}={
	0 => [qw/А Б В Г Д Е Ж З И К Л М Н О П Р С Т У Ф Х Ц Ч Ш Ы Э Ю Я/],
	1 => [qw/ЗДЕСЬ НАПИШИТЕ СЛОВА КОТОРЫЕ БУДУТ ИСПОЛЬЗОВАТЬСЯ В КАПЧЕ ЧЕРЕЗ ПРОБЕЛ/],
	2 => ['А','Б','В','Г','Д','Е','Ж','З','И','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Ы','Э','Ю','Я',undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef],
	3 => ['А','Б','В','Г','Д','Е','Ж','З','И','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Ы','Э','Ю','Я',undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef],
};


$SETTINGS{LANG}={
THREAD_NOT_EXISTS =>'Такого треда не существует!',
NO_REPLIES => 'Вы не можите оставлять сообщения в этом разделе!',
NO_FILES => 'Тут нельзя загружать файлы!',
UNUSUAL => 'В этом поле не должно быть таких символов!',
THREADS_WITH_FILES => 'Загрузите файл для создания треда',
TOOLONG => 'Слишком длинная тема, имя или email!',
TOOLONG_MSG => 'Слишком длинное сообщение!',
NO_MSG => 'Нельзя создавать пустые сообщения!',
WRONG_CAPTCHA => 'Неверно введена капча!',
NO_PASSWORD => 'Вы не ввели пароль!',
NO_FILE => 'Ошибка при загрузке файла',
CANT_CREATE_THUMBNAIL => 'Невозможно создать превью.',
UNSUPPORTED_FORMAT => 'Запрещено загружать файлы этого формата.',
TOO_BIG_RES => 'Слишком большие размеры картинки.',
FILE_TOO_BIG => 'Размер файла слишком большой',
UPLOADING_ERROR => 'Некоторые файлы не были загружены',
HACK_TRY => 'Ты что, кулхацкер дохуя? Съебал отсюда, блядь!',
NO_POST => 'Такого сообщения не существует!',
WRONG_PASSWORD=> 'Неверный пароль!',
DELETING_ERROR => 'Некоторы посты не были удалены',
BANNED => 'Вы забанены. Причина: ',
TOO_FAST => 'Слишком быстрый постинг. Введите капчу',
SEARCH_TOO_FAST => 'Пользоваться поиском разрешается не чаще, чем раз в 5 секунд',
SEARCH_TOO_LONG => 'Слишком длинный поисковой запрос',
SEARCH_REGEXP_ERROR => 'Ошибка в регулярном выражении',
NO_THREADS => 'Тут нельзя содавать треды',
};

$SETTINGS{stylesheets}=[map
	{
		my %sheet;
		$sheet{filename}=$_;

		($sheet{title})=m!([^/]+)\.css$!i;
		$sheet{title}=ucfirst $sheet{title};
		$sheet{title}=~s/_/ /g;
		$sheet{title}=~s/ ([a-z])/ \u$1/g;
		$sheet{title}=~s/([a-z])([A-Z])/$1 $2/g;

		if($sheet{title} eq 'Photon') { $sheet{default}=1;  }
		else { $sheet{default}=0; }

		\%sheet;
	} glob('css/*.css')];


sub SETTINGS_DEFAULTS {$SETTINGS{SECTION} = 'error'; return \%SETTINGS;}

sub GLOBAL_SETTINGS{
	return {
	ANTIDDOS_RCOUNT =>20000000,
	MODER =>'ПАСС ДЛЯ АДМИНКИ',
	ADMIN =>'',
	SECRET =>'123321',
	TRIPKEY => chr(0x2665),
	ACAPTCAHA_TIMEOUT => 60,
	SEARCH_TIMEOUT => 5
	}
}

sub GET_SECTIONS{
return {

    b => {%SETTINGS,
        TITLE => 'site.site.com - Бред',
        },
		#### пример с флэшем ####
	f => {%SETTINGS,
        TITLE => 'site.com - Flash',
		FILETYPES =>  {%{$SETTINGS{FILETYPES}}, swf => '/swf.png' },
		MAX_FILESIZE  =>  1024*1024*30
        },
	ls => {%SETTINGS,
        TITLE => 'site.com - exe файлы.',
		FILETYPES =>  {%{$SETTINGS{FILETYPES}}, exe => '/exe.png', zip => '/zip.png' },
		MAX_FILESIZE  => 1024*1024*100,
		DEFAULT_NAME => 'Лоля'
        },
	};
}
1;
