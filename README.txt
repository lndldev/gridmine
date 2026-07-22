
##trucs à améliorer auxquels je pensais 

1 - son
j'ai ajouté quelques sound fx, il faut juste les brancher
on pourrait faire un random entre plusieurs fx pour varier un peu ?

éventuelllement un son différent pour un dégat vs un bloc cassé
et eventuellement différent pour une pierre cassée vs un métal/gemme

2 - minage en aoe
si jamais on a des outils du genre bombe/ foreuse qui mine plusieurs cases à la fois notre système de dégat et last clicked est pourri
mais si on stock les pv de tous les blocks ca devient un peu un bordel...

proposition : on stocke une liste des coordonnées de blocks affectés avec leurs dégats subis (plutot que pour 100% de la grille) 
on fait un script du genre "au bout de 5 secondes sans miner, on soigne tous les blocks de 1 par seconde" ?

on peut aussi prévoir un pattern d'aoe de dégats, ca peut être un tableau de coordonnées relatives à la position du click qu'on peut faire évoluer avec des bonus ?

genre si on veut gérer une aoe d'une seule case, ca sera [(0, 0)]
si ca sera une croix d'une portée de 1 ca pourrait être [(0,0),(0,1),(1,0),(-1,0), (0,-1)]
etc

mais il faudrait un symbole qui ne soit pas une cible alors, plus qqch qui signifie "endommagé"
faire clignotter ? ca doit être possible mais je ne sais pas comment

Tout ceci n'est une question importante que si on veut pouvoir miner en AOE, sinon, notre système est très suffisant

3 - typage
il semblerait qu'on peut faire des TYPE sur des entités, je pense que ca va être très vite très utile de faire des types de terrain, 
mais je suis pas trop sur de comment on gère ca dans godot

terrain.get_cell_tile_data


4 - où mettre l'ui

5 - idée : chercher à challenger avec chaque niveau pour atteindre un layout "opti" avec seulement les salles fermées qui peuvent produire etc (cf dome keeper)
ca demande aussi un peu de level design pour contraindre la forme de chaque niveau

6 - réfléchir à l'idée de biomes
