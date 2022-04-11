SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- Prénom et nom des malades affiliés à la mutuelle « MAAF »

select nom, prenom
from malade
where mutuelle = 'MAAF';

-- Prénom et nom des infirmier(ères) travaillant pendant la rotation de nuit

select E.prenom, E.nom
from infirmier I, employe E
where I.rotation = 'nuit' 
	and I.numero = E.numero;

-- Donner pour chaque service, son nom, son bâtiment, ainsi que les prénom, nom et spécialité de son directeur

select S.nom, S.batiment, E.nom, E.prenom, D.specialite
from service S, employe E, docteur D
where S.directeur = E.numero
	and E.numero = D.numero;

-- or

select s.nom, s.batiment, e.prenom, e.nom, d.specialite
from (employe e natural join docteur d) inner join service s on s.directeur = d.numero;

-- Donner pour chaque lit du bâtiment « B » de l’hôpital occupé par un malade affilié à une
-- mutuelle dont le nom commence par « MN... », le numéro du lit, le numéro de la chambre, le nom du
-- service ainsi que le prénom, le nom et la mutuelle du malade l’occupant.

select H.lit, H.no_chambre, S.nom, M.nom, M.prenom, M.mutuelle
from hospitalisation H, service S, malade M
where H.no_malade = M.numero and M.mutuelle like 'MN%'
	and H.code_service = S.code and S.batiment = 'B';

-- Quelle est la moyenne des salaires des infirmiers(ères) par service ?

select S.code, avg(I.salaire)
from service S, infirmier I
where S.code = I.code_service
group by S.nom;

-- Pour chaque service du bâtiment « A » de l’hôpital, quel est le nombre moyen de lits par chambre ?

select C.code_service, avg(C.nb_lits)
from service S, chambre C 
where C.code_service = S.code
	and S.batiment = 'A'
group by C.code_service;

-- Pour chaque malade soigné par plus de 3 médecins donner le nombre total de ses médecins ainsi
-- que le nombre correspondant de spécialités médicales concernées.

select M.nom, M.prenom, count(distinct S.no_docteur) as nb_soignants, count(distinct D.specialite) as nb_secialites
from soigne S, malade M, docteur D
where M.numero = S.no_malade 
	and D.numero = S.no_docteur
group by S.no_malade
having count(distinct S.no_docteur) > 3
order by M.nom;

-- Pour chaque service quel est le rapport entre le nombre d’infirmier(ères) affecté(es) au service et
-- le nombre de malades hospitalisés dans le service ?

select S.nom, count(distinct I.numero)/count(distinct H.no_malade) as `nom rapport i sur m`
from infirmier I, hospitalisation H, service S
where I.code_service = H.code_service
and S.code = I.code_service and S.code = H.code_service
group by S.nom
order by S.nom;

-- or

select H.code_service, count(distinct I.numero)/count(distinct H.no_malade) as `nom rapport i sur m`
from infirmier I, hospitalisation H
where I.code_service = H.code_service
group by H.code_service;

-- Prénom et nom des docteurs ayant au moins un malade hospitalisé ?

select distinct D.prenom, D.nom
from soigne S, employe D, hospitalisation H
where D.numero = S.no_docteur
and H.no_malade = S.no_malade
order by D.nom;

-- Prénom et nom des docteurs n’ayant aucun malade hospitalisé

select D.prenom, D.nom
from employe D, soigne S LEFT JOIN hospitalisation H
ON H.no_malade = S.no_malade
where D.numero = S.no_docteur
group by D.numero
having count(distinct H.no_malade) = 0
order by D.nom;

-- or

select e.prenom, e.nom
from employe e natural join docteur d
where d.numero not in (select s.no_docteur
						from soigne s natural join hospitalisation h)
order by e.nom;

-- Pour chaque docteur, retrouver le nombre de ses malades hospitalisés, y compris ceux dont le nombre est 0.

select D.prenom, D.nom, count(distinct H.no_malade) as `numberOfMalade`
from employe D,soigne S LEFT JOIN hospitalisation H
ON H.no_malade = S.no_malade
where D.numero = S.no_docteur
group by D.numero
order by numberOfMalade desc;

-- Bâtiment et numéro des chambres occupées par au moins un malade (hospitalisé)

select distinct S.batiment, H.no_chambre
from service S, hospitalisation H
where S.code = H.code_service;

-- Bâtiment et numéro des chambres vides (aucun malade n’y est hospitalisé)

select s.batiment, c.no_chambre
from service s join chambre c on s.code = c.code_service
where (c.code_service, c.no_chambre) not in (select code_service, no_chambre from hospitalisation);

-- Pour chaque chambre, donner le bâtiment, le numéro, le nombre total de lits et le nombre des
-- lits occupés par les malades qui y sont hospitalisés, y compris quand le nombre est 0.

select s.batiment, c.no_chambre, c.nb_lits, count(*) as `nblits occupes`
from service s inner join chambre c on s.code = c.code_service
	inner join hospitalisation h on (c.code_service = h.code_service and c.no_chambre = h.no_chambre)
group by s.batiment, c.no_chambre, c.nb_lits
union
select s.batiment, c.no_chambre, c.nb_lits, 0
from service s inner join chambre c on s.code = c.code_service
where (c.code_service, c.no_chambre) not in (select code_service, no_chambre from hospitalisation);

-- or

select s.batiment, c.no_chambre, c.nb_lits, count(h.no_chambre) as `nblits_occupes`
from service s inner join chambre c on s.code = c.code_service
left join hospitalisation h on (c.code_service = h.code_service)
group by s.batiment, c.no_chambre, c.nb_lits
order by s.batiment, c.no_chambre;

-- Prénom et nom des docteurs ayant un malade hospitalisé dans chaque service

select e.prenom, e.nom
from employe e natural join docteur d
where not exists (select *
					from service s
					where not exists (select *
										from hospitalisation h, soigne so
										where so.no_malade = h.no_malade
										and so.no_docteur = e.numero	
										and h.code_service = s.code))
order by e. nom;

-- or

select e.prenom, e.nom
from (employe e natural join docteur d)
	inner join soigne so on so.no_docteur = e.numero
	inner join hospitalisation h on so.no_malade = h.no_malade
group by e.prenom, e.nom
having count(distinct h.code_service) = (select count(*) from_service)
order by e.nom;

-- Prénom et nom des docteurs ayant un malade hospitalisé dans chaque chambre dont l’infirmier
-- surveillant a pour nom « Roddick »

select e.prenom, e.nom
from employe e natural join docteur d
where not exists (select *
					from chambre c
					where c.surveillant in (select numero from employe where nom = 'Roddick')
						and not exists (select *
										from hospitalisation h, soigne so
										where so.no_malade = h.no_malade
											and so.no_docteur = e.numero
											and h.code_service = c.code_service and h.no_chambre = c.no_chambre))
order by e.nom;

-- or

select e.prenom, e.nom
from employe e, soigne so, hospitalisation h, chambre c
where so.no_docteur = e.numero and so.no_malade = h.no_malade and
	c.code_service = h.code_service and c.no_chambre = h.no_chambre
	and c.surveillant in (select numero from employe where nom = 'Roddick')
group by e.prenom, e.nom
having count(distinct h.code_service, h.no_chambre) = (select count(*)
															from chambre
															where surveillant in (select numero from employe where nom ='Roddick'))
order by e.nom;

-- Prénom et nom des malades soignés par le directeur du service dans lequel ils sont hospitalisés

select m.prenom, m.nom
from soigne s, hospitalisation h, malade m, service se
where s.no_malade = m.numero
and s.no_malade = h.no_malade
and h.code_service = se.code
and s.no_docteur = se.directeur
order by nom

-- Quelles sont les chambres qui ont des lits disponibles dans le service de cardiologie (dont le
-- nom est « Cardiologie »)
select c.no_chambre
from chambre c, service s
where c.code_service = s.code
and s.nom = 'Cardiologie'
and nb_lits > (select count(*)
			from hospitalisation h
			where h.code_service = s.code
			and h.no_chambre = c.no_chambre);




 
 
 
