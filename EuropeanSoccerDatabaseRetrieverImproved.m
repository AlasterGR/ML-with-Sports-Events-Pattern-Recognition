% This script file provides fundamental pre-processing operations for the
% European Soccer Database.

% Define the database file.
database_file = 'database.sqlite';

% Create a connection to the database.
fprintf('\n Establishing connection to %s\n',database_file);
conn = sqlite(database_file,'readonly');

% Retrieve the contents of the Match table containing the following
% columns: {id, country_id, league_id, season, stage, date, match_api_id, 
% home_team_api_id, away_team_api_id, home_team_goal, away_team_goal, 
% home_player_X1, home_player_X2, home_player_X3, home_player_X4, 
% home_player_X5, home_player_X6, home_player_X7, home_player_X8, 
% home_player_X9, home_player_X10, home_player_X11, away_player_X1, 
% away_player_X2, away_player_X3, away_player_X4, away_player_X5, 
% away_player_X6, away_player_X7, away_player_X8, away_player_X9, 
% away_player_X10, away_player_X11, home_player_Y1, home_player_Y2, 
% home_player_Y3, home_player_Y4, home_player_Y5, home_player_Y6, 
% home_player_Y7, home_player_Y8, home_player_Y9, home_player_Y10, 
% home_player_Y11, away_player_Y1, away_player_Y2, away_player_Y3, 
% away_player_Y4, away_player_Y5, away_player_Y6, away_player_Y7, 
% away_player_Y8, away_player_Y9, away_player_Y10, away_player_Y11, 
% home_player_1, home_player_2, home_player_3, home_player_4, home_player_5, 
% home_player_6, home_player_7, home_player_8, home_player_9, home_player_10, 
% home_player_11, away_player_1, away_player_2, away_player_3, away_player_4, 
% away_player_5, away_player_6, away_player_7, away_player_8, away_player_9, 
% away_player_10, away_player_11, goal, shoton, shotoff, foulcommit, card, 
% cross, corner, possession, B365H, B365D, B365A, BWH, BWD, BWA, IWH, IWD, 
% IWA, LBH, LBD, LBA, PSH, PSD, PSA}.
MatchColumnNames = {'id', 'country_id', 'league_id', 'season', 'stage', ...
'date', 'match_api_id','home_team_api_id', 'away_team_api_id',...
'home_team_goal', 'away_team_goal','home_player_X1', 'home_player_X2', ...
'home_player_X3', 'home_player_X4', ...
'home_player_X5', 'home_player_X6', 'home_player_X7', 'home_player_X8', ...
'home_player_X9', 'home_player_X10', 'home_player_X11', 'away_player_X1',... 
'away_player_X2', 'away_player_X3', 'away_player_X4', 'away_player_X5',... 
'away_player_X6', 'away_player_X7', 'away_player_X8', 'away_player_X9', ...
'away_player_X10', 'away_player_X11', 'home_player_Y1', 'home_player_Y2', ...
'home_player_Y3', 'home_player_Y4', 'home_player_Y5', 'home_player_Y6', ...
'home_player_Y7', 'home_player_Y8', 'home_player_Y9', 'home_player_Y10', ...
'home_player_Y11', 'away_player_Y1', 'away_player_Y2', 'away_player_Y3', ...
'away_player_Y4', 'away_player_Y5', 'away_player_Y6', 'away_player_Y7', ...
'away_player_Y8', 'away_player_Y9', 'away_player_Y10', 'away_player_Y11', ...
'home_player_1', 'home_player_2', 'home_player_3', 'home_player_4', 'home_player_5', ...
'home_player_6', 'home_player_7', 'home_player_8', 'home_player_9', 'home_player_10', ...
'home_player_11', 'away_player_1', 'away_player_2', 'away_player_3', 'away_player_4', ...
'away_player_5', 'away_player_6', 'away_player_7', 'away_player_8', 'away_player_9', ...
'away_player_10', 'away_player_11', 'goal', 'shoton', 'shotoff', 'foulcommit', 'card',... 
'cross', 'corner', 'possession', 'B365H', 'B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', ...
'IWA', 'LBH', 'LBD', 'LBA', 'PSH', 'PSD', 'PSA'};
% Not all columns of the Match table appear to contain data. Thus, we form
% a specialized query to retrieve the subset of columns that are non-empty.
% This is done by forming a vector which stores all the non-empty columns 
% of the Match table.
ids = [6:11,86:97];
sqlquery = 'select ';
for idx = ids
    if(idx==ids(end))
        sqlquery = strcat([sqlquery,MatchColumnNames{idx}]);
    else
        sqlquery = strcat([sqlquery,MatchColumnNames{idx},',']);
    end
end
sqlquery = strcat([sqlquery ' from Match']);
MatchCell = fetch(conn,sqlquery);
Match = cell2table(MatchCell,'VariableNames',MatchColumnNames(ids));
% Release variable MatchCell.
clear MatchCell

% Remove rows from Match table for which the betting odds are zero for at
% least one betting company.
Match = standardizeMissing(Match,0,'DataVariables',{'B365H','B365D', 'B365A', 'BWH', 'BWD', 'BWA', 'IWH', 'IWD', 'IWA', 'LBH', 'LBD', 'LBA' });
Match = rmmissing(Match);

% Retrieve the contents of the Team_Attributes table containing the
% following columns: {id, team_fifa_api_id, team_api_id, date, buildUpPlaySpeed, 
% buildUpPlaySpeedClass, buildUpPlayDribbling, buildUpPlayDribblingClass, 
% buildUpPlayPassing, buildUpPlayPassingClass, buildUpPlayPositioningClass, 
% chanceCreationPassing, chanceCreationPassingClass, chanceCreationCrossing, 
% chanceCreationCrossingClass, chanceCreationShooting, chanceCreationShootingClass, 
% chanceCreationPositioningClass, defencePressure, defencePressureClass, defenceAggression, 
% defenceAggressionClass, defenceTeamWidth, defenceTeamWidthClass,
% defenceDefenderLineClass}.
TeamAttributesColumnNames = {'id','team_fifa_api_id','team_api_id',...
'date','buildUpPlaySpeed','buildUpPlaySpeedClass','buildUpPlayDribbling',...
'buildUpPlayDribblingClass','buildUpPlayPassing','buildUpPlayPassingClass',... %10%
'buildUpPlayPositioningClass','chanceCreationPassing','chanceCreationPassingClass',...
'chanceCreationCrossing','chanceCreationCrossingClass','chanceCreationShooting',...
'chanceCreationShootingClass','chanceCreationPositioningClass','defencePressure',...
'defencePressureClass','defenceAggression','defenceAggressionClass',...
'defenceTeamWidth','defenceTeamWidthClass','defenceDefenderLineClass'};
% Not all columns of the Team_Attributes table appear to contain data. Thus, we form
% a specialized query to retrieve the subset of columns that are non-empty.
% This is done by forming a vector whict stores all the non-empty columns 
% of the Match table.
% Not all columns will be needed for the assignment. We will not be
% processing those columns at all.
ids = [3:5,9,12,14,16,19,21,23];
sqlquery = 'select ';
for idx = ids
    if(idx==ids(end))
        sqlquery = strcat([sqlquery,TeamAttributesColumnNames{idx}]);
    else
        sqlquery = strcat([sqlquery,TeamAttributesColumnNames{idx},',']);
    end
end
sqlquery = strcat([sqlquery ' from Team_Attributes']);
TeamAttributesCell = fetch(conn,sqlquery);
TeamAttributes = cell2table(TeamAttributesCell,'VariableNames',TeamAttributesColumnNames(ids));
% Release variable TeamAttributesCell.
clear TeamAttributesCell

% Close connection.
close(conn);
fprintf('\n Closed connection to database : %s\n',database_file);