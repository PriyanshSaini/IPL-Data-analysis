 CREATE TABLE deliveries(
   match_id         INTEGER  NOT NULL,
   inning           INTEGER  NOT NULL,
   batting_team     VARCHAR(27) NOT NULL,
   bowling_team     VARCHAR(27) NOT NULL,
   over_no             INTEGER  NOT NULL,
   ball             INTEGER  NOT NULL,
   batsman          VARCHAR(17) NOT NULL,
   non_striker      VARCHAR(17) NOT NULL,
   bowler           VARCHAR(17) NOT NULL,
   is_super_over_no    BIT  NOT NULL,
   wide_runs        INTEGER  NOT NULL,
   bye_runs         INTEGER  NOT NULL,
   legbye_runs      INTEGER  NOT NULL,
   noball_runs      INTEGER  NOT NULL,
   penalty_runs     INTEGER  NOT NULL,
   batsman_runs     INTEGER  NOT NULL,
   extra_runs       INTEGER  NOT NULL,
   total_runs       INTEGER  NOT NULL,
   player_dismissed VARCHAR(17),
   dismissal_kind   VARCHAR(17),
   fielder          VARCHAR(20)
);


CREATE TABLE matches(
   id              INTEGER  NOT NULL PRIMARY KEY,
   season          INTEGER  NOT NULL,
   city            VARCHAR(14) NOT NULL,
   date            DATE  NOT NULL,
   team1           VARCHAR(27) NOT NULL,
   team2           VARCHAR(27) NOT NULL,
   toss_winner     VARCHAR(27) NOT NULL,
   toss_decision   VARCHAR(5) NOT NULL,
   result          VARCHAR(6) NOT NULL,
   dl_applied      BIT  NOT NULL,
   winner          VARCHAR(27) NOT NULL,
   win_by_runs     INTEGER  NOT NULL,
   win_by_wickets  INTEGER  NOT NULL,
   player_of_match VARCHAR(17) NOT NULL,
   venue           VARCHAR(52) NOT NULL,
   umpire1         VARCHAR(21),
   umpire2         VARCHAR(14),
   umpire3         VARCHAR(30)
);

--WHAT ARE THE TOP 5 PLAYERS WITH THE MOST PLAYER OF THE MATCH AWARDS?

select player_of_match,
count(*) as award_count
from matches
group by player_of_match
order by award_count desc
limit 5;

--HOW MANY MATCHES WERE WON BY EACH TEAM IN EACH SEASON?
select season,
winner as team,
count(*) as total_matches_won
from matches
group by season,winner
order by season,total_matches_won desc;

--WHAT IS THE AVERAGE STRIKE RATE OF BATSMEN IN THE IPL DATASET?
select batsman,(sum(total_runs)/count(ball))*100 as strike_rate
from deliveries
group by batsman
order by strike_rate desc;

--WHAT IS THE NUMBER OF MATCHES WON BY EACH TEAM BATTING FIRST VERSUS BATTING SECOND?

select batting_team as team,
'Batting_First'as match_type,
count(*) as matches_won
from(
select case when win_by_runs > 0 then team1
else team2
end as batting_team
from matches
where winner!='Tie') as batting_first_teams
group by batting_team

union all

select batting_team as team,
'Batting_second' as match_type,
count(*) as matches_won
from(
select case when win_by_wickets > 0 then team2
else team1
end as batting_team
from matches
where winner!='Tie') as batting_second_teams
group by batting_team
order by matches_won desc;

--WHICH BATSMAN HAS THE HIGHEST STRIKE RATE (MINIMUM 200 RUNS SCORED)?

select batsman,(sum(batsman_runs)*100/count(*))
as strike_rate
from deliveries group by batsman
having sum(batsman_runs)>=200
order by strike_rate desc
limit 5;

--HOW MANY TIMES HAS EACH BATSMAN BEEN DISMISSED BY THE BOWLER 'MALINGA'?

select batsman,
count(*) as total_dismisal
from deliveries
where player_dismissed is not null
and bowler = 'SL Malinga'
group by batsman
order by total_dismisal desc;

--WHAT IS THE AVERAGE PERCENTAGE OF BOUNDARIES (FOURS AND SIXES COMBINED) HIT BY EACH BATSMAN?

select batsman,avg(case when batsman_runs=4 or batsman_runs=6
then 1 else 0 end)*100 as avg_boundaries
from deliveries
group by batsman
order by avg_boundaries desc;

--WHAT IS THE AVERAGE NUMBER OF BOUNDARIES HIT BY EACH TEAM IN EACH SEASON?
select season,batting_team,avg(fours+sixes) as average_boundaries
from(select season,match_id,batting_team,
sum(case when batsman_runs=4 then 1 else 0 end)as fours,
sum(case when batsman_runs=6 then 1 else 0 end) as sixes
from deliveries,matches 
where deliveries.match_id=matches.id
group by season,match_id,batting_team) as team_bounsaries
group by season,batting_team
order by average_boundaries desc;

--WHAT IS THE HIGHEST PARTNERSHIP (RUNS) FOR EACH TEAM IN EACH SEASON?

select season,batting_team,max(total_runs) as highest_partnership
from(select season,batting_team,partnership,sum(total_runs) as total_runs
from(select season,match_id,batting_team,over_no,
sum(batsman_runs) as partnership,sum(batsman_runs)+sum(extra_runs) as total_runs
from deliveries,matches where deliveries.match_id=matches.id
group by season,match_id,batting_team,over_no) as team_scores
group by season,batting_team,partnership) as highest_partnership
group by season,batting_team
order by highest_partnership desc;


--HOW MANY EXTRAS (WIDES & NO-BALLS) WERE BOWLED BY EACH TEAM IN EACH MATCH?

select m.id as match_no,d.bowling_team,
sum(d.extra_runs) as extras
from matches as m
join deliveries as d
on d.match_id = m.id
where extra_runs > 0
group by m.id, bowling_team
order by extras desc;

--WHICH BOWLER HAS THE BEST BOWLING FIGURES (MOST WICKETS TAKEN) IN A SINGLE MATCH?

select m.id as match_no,d.bowler,
count(*) as wicket_taken
from matches as m
join deliveries as d 
on d.match_id = m.id
where d.player_dismissed is not null
group by m.id, d.bowler
order by wicket_taken desc; 

--HOW MANY MATCHES RESULTED IN A WIN FOR EACH TEAM IN EACH CITY?

select m.city,
case when m.team1=m.winner then m.team1
when m.team2=m.winner then m.team2
else 'draw'
end as winning_team,
count(*) as wins
from matches as m
join deliveries as d 
on d.match_id=m.id
where m.result!='Tie'
group by m.city,winning_team
order by wins desc;

--HOW MANY TIMES DID EACH TEAM WIN THE TOSS IN EACH SEASON?

select season,
toss_winner,
count(*) as toss_wins
from matches
group by season, toss_winner
order by season,toss_wins desc;

--WHAT IS THE AVERAGE NUMBER OF RUNS SCORED IN EACH OVER OF THE INNINGS IN EACH MATCH?

select m.id,d.inning,d.over_no,
avg(d.total_runs) as avg_runs_per_over
from matches as m
join deliveries as d 
on d.match_id = m.id
group by m.id,d.inning,d.over_no
order by avg_runs_per_over desc;

--WHICH TEAM HAS THE HIGHEST TOTAL SCORE IN A SINGLE MATCH?

select m.season, m.id as match_no,d.batting_team,
sum(d.total_runs) as total_score
from matches as m
join deliveries as d
on d.match_id = m.id
group by m.season, m.id, batting_team
order by m.season, total_score desc;

--WHICH BATSMAN HAS SCORED THE MOST RUNS IN A SINGLE MATCH?

select m.season,m.id as match_no, d.batsman,
sum(d.batsman_runs) as highest_score
from deliveries as d
join matches as m
on m.id = d.match_id
group by m.season,m.id,d.batsman
order by m.season, highest_score desc;





