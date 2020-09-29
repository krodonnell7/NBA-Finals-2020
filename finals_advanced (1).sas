libname nbastats xlsx "/home/u48736772/cert/excel/NBA_Team_Stats_2019.xlsx";
libname nba2 xlsx "/home/u48736772/cert/excel/NBA_Season_2.xlsx";
options validvarname=v7;

*cleaning up data to include only 4 remaining playoff teams and creating ovr and efgpct variables;

data team_stats;
	retain Team OVR ovr_no_tov eFGpct _2P _3P FG FGA FG_ TRB TOV PTS FT FTA FT_ PF WIN_PCT;
	set nbastats.sheet1;
	where team in("Los Angeles Lakers","Denver Nuggets","Miami Heat","Boston Celtics");
	eFGpct=round(((_2P + 1.5*_3P) / FGA),.001);
	keep eFGpct _2P _3P Team FG FGA FG_ TRB ORB DRB AST TOV PTS STL BLK FT FTA FT_ ovr ovr_no_tov;
	ovr=round((.2*TRB - .25*TOV + .15*FT_ + .4*eFGpct),0.001);
	ovr_no_tov=round((.2*TRB + .15*FT_ + .4*eFGpct),0.001);
	team=compress(team, '*');

run;

*sorting and reporting on data, including only team, ovr, efgpct;

proc sort data=team_stats out=byovr;
	by descending ovr;
run;

proc sort data=team_stats out=by_eFG;
	by descending eFGpct;
run;

title "Ranking the Remaining NBA Teams by Overall Score (Based On Shooting, Rebounding, Turnovers, Free Throws)";
proc print data=byovr obs="Rank";
	var Team;
	var OVR / style={backgroundcolor=pagy};
	var efgpct;
run;
title;

title2 "Ranking the Remaining NBA Teams by Effective Field Goal Percentage";
proc print data=work.by_eFG obs="Rank";
	var Team ovr;
	var efgpct / style={backgroundcolor=pagy};
run;
title2;

**************************************************************
Merging multiple data sets to include BLKA for proper analysis
**************************************************************;

proc sort data=nbastats.sheet1;
	by team;
run;
proc sort data=nba2.sheet1;
	by team;
run;

data full_stats;
	merge nbastats.sheet1 nba2.sheet1;
	by Team;
	PRED_WIN_PCT = - 0.0330*log(PTS) + 0.0587*(FT) + 0.0186*log(ORB) + 0.0543*log(DRB) + 0.0376*log(AST) - 0.0480*(TOV) + 0.0408*(STL) + 0.0186*log(BLK) - 0.0639*log(BLKA) - 0.0107*(PF);
	where team in("Los Angeles Lakers","Denver Nuggets","Miami Heat","Boston Celtics");
run;

proc sort data=full_stats;
	by descending pred_win_pct;
run;

title3 "Ranking the Remaining NBA Teams by Predicted Win Percentage from Regular Season Data";
proc print data=full_stats;
	var team;
	var pred_win_pct / style={backgroundcolor=pagy};
run;
title3;
	
**************************************************************
Same model but with only playoff stats instead of season stats
**************************************************************;

libname playoff xlsx "/home/u48736772/cert/excel/NBA_Playoff_Team.xlsx";

data playoff_team_stats;
	set playoff.sheet1;
	where team in("Los Angeles Lakers","Denver Nuggets","Miami Heat","Boston Celtics");
	PRED_WIN_PCT = - 0.0330*log(PTS) + 0.0587*(FTM) + 0.0186*log(OREB) + 0.0543*log(DREB) + 0.0376*log(AST) - 0.0480*(TOV) + 0.0408*(STL) + 0.0186*log(BLK) - 0.0639*log(BLKA) - 0.0107*(PF);
run;

proc sort data=playoff_team_stats;
	by descending pred_win_pct;
run;

title4 "Ranking the Remaining NBA Teams by Predicted Win Percentage from Playoff Data";
proc print data=playoff_team_stats;
	var team;
	var pred_win_pct / style={backgroundcolor=pagy};
run;
title4;