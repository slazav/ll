#!/usr/bin/perl -w
use strict;

use ll9;

#print "GROUPS:\n";
#ll9::yaml_groups();
#ll9::text_groups();
#ll9::json_groups();

#print "TAGS:\n";
#ll9::yaml_tags();
#ll9::text_tags();
#ll9::json_tags();

#print "ENTRY:\n";
#ll9::yaml_entry('2012','362');
#ll9::json_entry('2012','362');


ll9::html_head();
ll9::html_nav();
ll9::html_entry('2012','363');
ll9::html_tail();

