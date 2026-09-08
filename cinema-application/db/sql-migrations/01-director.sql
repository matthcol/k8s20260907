alter table movie add column director_id int null;

alter table movie add constraint fk_movie_director
	FOREIGN KEY (director_id)
	references person(id);
