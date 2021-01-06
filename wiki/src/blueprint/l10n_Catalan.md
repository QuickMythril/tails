Documentació per a la traducció del Tails al Català
===================================================

[[!toc levels=2]]

Com puc ajudar a traduir el Tails al català?
--------------------------------------------------
1. Si voleu ajudar a traduir el Tails, el primer que hauríeu de fer és subscriure-us a la llista de correu dels traductors al Català del Tails:
   - <https://www.autistici.org/mailman/listinfo/tails-l10n-ca>
   - Presenteu-vos a la llista i us posarem al dia de l'estat de la traducció.
   
2. En segon lloc us hauríeu de familiaritzar amb els [recursos per a traductors de Softcatalà](https://www.softcatala.org/recursos/), especialment:
   - [La Guia d'estil de softcatalá](https://www.softcatala.org/guia-estil-de-softcatala)
   
A partir d'aquí podreu triar entre traduir el programari especialitzat del Tails o el seu web, que són els dos recursos bàsics que hi ha per traudir.

* El Tails és un Debian especialment configurat. La major part del seu programari, doncs, forma part d'aquesta distribució de Linux i la seva traducció no la gestiona la comunitat del Tails, sinó la de Debian. En canvi, però, sí que podem traduir el programari específic del Tails. Per això fem servir la plataforma Transifex i trobareu més instruccions a [[*Translate Tails using Transifex*|contribute/how/translate/with_Transifex]].
  
* Per a la traducció del contingut del web (per ara, la nostra prioritat) es poden usar dues eines diferents:
  *  git
  *  plataforma weblate

Traducció del web oficial de Tails amb git
------------------------------------------
Per a traduir el web amb git heu de seguir les instruccions a [[*Translate Tails and its website using Git*|contribute/how/translate/with_Git]], tenint en compte que en el punt *1. Set up your own repository*, que indica que us creeu el vostre repositori, ja tenim creat un repositori per als traductors de Català, que el trobareu a <https://gitlab.com/tails-ca/tails>, i que hauríeu de fer servir.

En aquest repositori hi trobareu una branca *master* que conté el codi oficial de git. La branca *catalan* conté el codi amb la traducció al català. Hi ha altres branques *translate/xxxx* per a cada secció del web de Tails que estem traduïnt i que després incorporem a la branca *catalan*. Quan tinguem un mínim de traducció llesta podrem demanar que l'activin. Aquestes son les pàgines que hem de traduir en primer lloc: [[arxius del nucli a traduir|contribute/l10n_tricks/core_po_files.txt]]

Mitjançant la llista de correu ens coordinem per repartir-nos la traducció d'aquestes pàgines.


Traducció del web oficial de Tails amb Weblate
----------------------------------------------
Si ho preferiu, podeu traduir el web del Tails mitjançant una plataforma web que s'està provat: 

<https://translate.tails.boum.org/>

L'equip de traducció al Català encara no l'hem utilitzat i no hem establert, per tant, una operativa per a traduir amb Weblate. Però si la voleu fer servir, parlem-ne a la llista de correu i ens coordinem.


Consells de traducció
---------------------
A part de seguir les guies de traducció de softcatalà, cal tenir en compte que el web de Tails funciona amb [[ikiwiki]] i que aquest inclou un sistema de marcatge que cal traduir convenientment. Cal revisar com funcionen el [[enllaços wiki|ikiwiki/wikilink]] i les [[directives|ikiwiki/directive]], especialment els *!inline*.

### Enllaç ikiwiki: [ [ paraula ] ]

Els enllaços d'ikiwiki es corresponen a rutes d'URL. Per exemple: 

    [ [ Security ] ]

enllaça a la pàgina [[Security]].

Si volem traduir el text de l'enllaç, haurem de traduir l'enllaç ikiwiki de la següent manera:

    [ [ Seguretat|Security ] ]

per tenir l'enllaç a [[Seguretat|Security]] traduït.

La primera part abans del **|** es el text de l'enllaç, i la segona és l'enllaç en si mateix, en forma de ruta URL, que no canvia respecte l'original. Si l'enllaç corresponent en català existeix, l'ikiwiki ens hi portarà. Sinó, enllaça amb la versió en anglès.

(Per cert, en aquests exemples hi ha espais entre [ [  i ] ] i dins mateix, entre el text i els [ i ]. En la traducció s'ha de fer **sense espais**. Aquí hi són perquè sinó l'ikiwiki no mostra el codi com a exemple correctament.)

### Directiva *!inline*: [ [ !inline pages="xxxxxxx" raw="yes" sort="age" ] ]

Ens podem trobar amb aquesta directiva d'ikiwiki en alguns textos. És una forma d'incloure contingut des d'un altre arxiu. Dels *!inline* hem de traduir-ne la ruta a l'arxiu. Per exemple, aquesta directiva *!inline*:

    [ [ !inline pages="support/talk/languages.inline" raw="yes" sort="age" ] ]

L'hauríeu de traduir així:

    [ [!inline pages="support/talk/languages.inline.ca" raw="yes" sort="age"] ]

És a dir, afegir un *.ca* al final del nom de l'arxiu que s'incrustarà. Us heu d'assegurar que traduïu també l'arxiu corresponent, que hauríeu de trobar al sistema de fitxers, en aquest cas a *wiki/src/support/talk/*.
