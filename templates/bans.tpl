<include %TMPLDIR%/head.tpl>
<include %TMPLDIR%/admin_head.tpl>

<form action="admin.fpl" method="get" style="text-align: center;">
<input type="hidden" name="do" value="ban"/>
<center>
<table>
<tr><td>IP</td><td>Причина</td></tr>
<tr><td><input name="ip" /></td><td><input name="reason" /></td></tr><br/>
</table>
</center>
<input type="submit" name="submit" value="Забанить"/>
</form><br/>
<hr/>
<center>
<table width="50%">
<tr><td>IP</td><td>Причина</td><!--<td>Истекает</td>--></tr>
<loop $banned>
	<tr class="row<if %i++ and %i/2==int(%i/2)>2</else/>1</if>">
	<td><var $_id></td><td><var $reason></td><!--<td><var $expires></td>--><td width="50"><a href="admin.fpl?do=unban&ip=<var $_id>">Удалить</a></td></tr>
</loop>
</table>
</center>
<include %TMPLDIR%/foot.tpl>
<br>