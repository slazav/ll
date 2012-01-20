#!/usr/bin/perl -w
use strict;

use ll9;

#print "GROUPS:\n";
#ll9::print_groups('yaml');
#ll9::print_groups('text');
#ll9::print_groups('json');

#print "TAGS:\n";
#ll9::print_tags('yaml');
#ll9::print_tags('text');
#ll9::print_tags('json');

#print "GROUP INDEX\n";
#ll9::print_group_idx('yaml', '2011');
#ll9::print_group_idx('text', '2011');
#ll9::print_group_idx('json', '2011');


#print "ENTRY:\n";
#ll9::print_entry('yaml','2012','363');
#ll9::print_entry('json','2012','363');

#ll9::html_head();
#ll9::html_nav();
#ll9::html_entry('2012','363');
#ll9::html_tail();

#print "GROUP\n";
#ll9::print_group('yaml','2012');
#ll9::print_group('json','2012');

ll9::html_head();
print qq*
<script language="JavaScript">
  function toggle(id){
    v = document.getElementById(id).style.display;
    document.getElementById(id).style.display = (v=='none'?'':'none');}
</script>
*;


ll9::html_nav();
ll9::html_group('2012', 1);
ll9::html_tail();
