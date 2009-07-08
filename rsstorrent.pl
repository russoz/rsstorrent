#!/usr/bin/perl

use strict;
use warnings;

use Term::ProgressBar::Simple;
use WWW::Search::Mininova;
use LWP::Simple;
use XML::RSS::Parser::Lite;
use Getopt::Long;
use IMDB::Film;

#Default Options
my $rss = 'http://feeds.filmjabber.com/Movie-sourcecomDvdReleaseDates?format=xml';
my ($dir);
my $category = 'All';
my $parser = 'title';
my $relatorio = 'relatorio.txt';

GetOptions (

   "rss=s" => \$rss,
   "dir=s" => \$dir,
   "category=s" => \$category,
   "parser=s" => \$parser,
   "relatorio=s" => \$relatorio,
);

$| = 1; #autoflush on

my (@titles, %movies);


#Começo do programa

print "[*]Pegando RSS\n";
&parser;
print "\n[*]Procurando Filmes\n";
&mininova ;
print "\n[*]Salvando Filmes\n";
&save;

#Plugins
print "\n[*]Gerando relatório\n";
&relatorio;

#Fim do programa


#Faz o parser.

sub parser {

  my $rp = new XML::RSS::Parser::Lite;

  my $xml = get($rss);
  $rp->parse($xml);
  
  my $progress = Term::ProgressBar::Simple->new( $rp->count() );
  
  for ( my $i = 0 ; $i < $rp->count() ; $i++ ) {
     my $it = $rp->get($i);
     push (@titles, $it->get($parser) );
     $progress++;
  }

}

#Procura o que foi encontrado com o parser no Mininova.

sub mininova {

  my $progress = Term::ProgressBar::Simple->new( scalar(@titles) );

  my $mini = WWW::Search::Mininova->new( category => $category, sort => 'Seeds', );

  foreach my $titulo ( @titles ) {
     $mini->search( $titulo );
     my $result = $mini->result(0);
     if ( defined $result->{download_uri} ) {
	$movies{$result->{name}} = $result->{download_uri};
	$progress++
     }

  }

}

#Salva todos os .torrent encontrados no Mininova.

sub save {

  my $progress = Term::ProgressBar::Simple->new( scalar(keys %movies) );

  while (my($name,$url) = each %movies) {

   open my $files, q{>}, "$dir$name.torrent"
	or warn $!;
   print $files get($url);
   $progress++;
  }

}

#Plugins

#Gera um relatório com base no que foi achado pelo Parser.
sub relatorio {

# Parse already stored HTML page from IMDB

  open my $RELA, ">", "$relatorio" or
	die "Não pode abrir o relatório $!\n";

  my $progress = Term::ProgressBar::Simple->new( scalar(@titles) );

  foreach my $imdb (@titles) {

     my $imdbObj = new IMDB::Film(crit => $imdb);

     if($imdbObj->status) {

	print $RELA "[+]Title: ".$imdbObj->title() . "\n";
	print $RELA "[+]Year: ".$imdbObj->year() . "\n";

	print $RELA "[+]Genre: ";
	foreach my $genero(@{ $imdbObj->genres() }) {

	  print $RELA "$genero ";

	}

	print $RELA "\n[+]Duration: ".$imdbObj->duration() . "\n";
	print $RELA "[+]Plot Symmary: ".$imdbObj->plot() . "\n\n";
  }
 
     else {
	print "[-]Something wrong: ".$imdbObj->error;
     }

  $progress++;

  }

}

__END__

=head1 RSSTorrent


=head1 SYNOPSIS

RSSTorrent [options] [file ...]

 Options:
   --rss Endereço do RSS
   --categoria Selecione a categoria: All, Anime, Books, Games, Movies, Music, Pictures, Software, TV Shows, Other, Featured.
   --parser Escolha o tipo do parser: title, url, description.
   --relatorio Nome do arquivo para salvar o relatório.

=head1 OPTIONS

=over 8

=item B<--rss>

Específica o RSS para fazer o parser.

=item B<--dir>

Específica o prefixo ou diretório aonde vai ser salvo, para salvar todos os torrents com o prefixo Filmes, apenas: --dir Filmes.
Para salvar na pasta filmes: --Filmes/.

=item B<--categoria>

Específica a categoria para busca torrent:
All, Anime, Books, Games, Movies, Music, Pictures, Software, TV Shows, Other, Featured.

=item B<--parser>

Específica qual vai ser o parser:
title, url, description.

=item B<--relatorio>

O nome do arquivo.

=back

=head1 DESCRIPTION

Este programa faz o parser de acordo com o RSS escolhido, baixa todos os arquivo .torrent e gera um relatório com todas as especificações do filme.

=cut

=head1 LICENSE

Este programa tem licença GPL:
L<http://www.gnu.org/licenses/gpl.html>

=head1 AUTHOR

Daniel de Oliveira Mantovani <daniel.oliveira.mantovani@gmail.com>
