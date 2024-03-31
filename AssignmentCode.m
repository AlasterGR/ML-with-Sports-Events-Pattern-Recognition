%%
% Όνομα-Επώνυμο-ΑΜ : Δαβάκης Αλέξανδρος   ΜΠΠΛ18013
% Όνομα-Επώνυμο-ΑΜ : Καμπυλαυκάς Ιωάννης  ΜΠΠΛ18024
% Όνομα-Επώνυμο-ΑΜ : Ανδρέας Κάππος       ΜΠΠΛ18027

% This is the Pattern Recognition assignment MATLAB code file for the
% "Informatics" Post Graduate Course
% It will be written in proper English since MATLAB has difficulty handling
% Greek encoded characters
tic ; diary AssignmentReport.txt ; warning('off') ;
%%  Processing and Preparing the data for the 1st, 2nd and 3rd Questions of the assignment
% tic;
%  We begin with a clear space
clc; clear; close all; 

%  We retrieve the initial data from the European Soccer Database file
fprintf("\n Retrieving relevant data from the database... \n");
EuropeanSoccerDatabaseRetrieverImproved; % This is a slightly improved version of the original file, where we retrieve the strictly relevant data.

%  Clear our workspace of everything but the two matrices we will be working with
fprintf("\n Clearing workspace of the unneeded variables... \n");
clearvars -except Match TeamAttributes;

% If an odds vector has a coordinate of 0, its entire row needs to be
% removed. Obsolete if using the "EuropeanSoccerDatabaseRetrieverImproved" script.
% fprintf("\n Removing irrelevant rows from Match table... \n");
% [rowOf0,~] = find(~Match{:,12:23});
% Match(rowOf0,:)=[]; % new number of lines is 22467. Initial number of lines is 22592

% We build the column of Response for the classifier
Match_row_size= size(Match,1);
results = zeros(Match_row_size, 1);
[rowOfH,columnOfH] = find((Match{:,'home_team_goal'}-Match{:,'away_team_goal'})>0);
[rowOfA,columnOfA] = find((Match{:,'home_team_goal'}-Match{:,'away_team_goal'})<0);
[rowOfD, ~] = find((Match{:,'home_team_goal'}-Match{:,'away_team_goal'})==0);  % test
results(rowOfH,:)=1;
results(rowOfA,:)=2;
results(rowOfD,:)=3;  %  3 is from the result of Draw
fprintf("\n Response column for the predictive models has been built. \n");

% We build the sets for each betting company, that will be fed to the classifier
fprintf("\n Building the various sets needed for the training of the models... \n");
yB365 =[double(Match.B365H), double(Match.B365D), double(Match.B365A)];
yBW =  [double(Match.BWH),   double(Match.BWD), double(Match.BWA)] ;
yIW =  [double(Match.IWH),   double(Match.IWD), double(Match.IWA)] ;
yLB =  [double(Match.LBH),   double(Match.LBD), double(Match.LBA)] ;
B365 = [yB365, results];
BW   = [yBW, results];
IW   = [yIW, results];
LB   = [yLB, results];

%  We save all our progress so far.
save("AssignmentMaterials.mat", 'yB365', 'yBW', 'yIW', 'yLB', 'Match', 'results', 'TeamAttributes');
%  Let's save all the material that the 1st Question of the Assignment requires.
save("FeaturesBCompanies.mat", 'B365', 'BW', 'IW', 'LB');
fprintf("\n Relevant files have been saved. Data preparation for answering the 1st, 2nd and 3rd Question has finished. This Section has completed successfully. \n");
% toc
%% Preparing the data for the 3rd Question of the Assignment.
% tic

%  We clear the workspace but keep the Command Window text as part of the demonstration
clc ; clear ; load AssignmentMaterials.mat ;
fprintf("\n Clearing Workspace and loading required data... \n");

fprintf("\n Checking information matching between the various used data... \n");
inindx=find( ismember(Match.date, TeamAttributes.date) );
fprintf('\n For the given material, there are only %u matches, that is %.2f%% of the entire database, in which their team''s attributes were recorded. \n', length(inindx), ( length(inindx)/size(Match, 1) )*100 ) ;

fprintf('\n We now process the needed information regarding the attributes of the teams... \n');
%  We now remove the 'date' variable from the two tables since it will be irrelevant
TeamAttributes.date =[]; Match.date =[];

%  We are left with repeated entries of the same team's attributes at various seasons.
%  Thus, we opt to take a mean of the observed attributes for each team, in order to complete the table needed for the assignment  
TeamAttributes = sortrows(TeamAttributes,'team_api_id');  %  We make sure to have our table sorted by team_api_id
Team_Avg_Attributes(1, :)=TeamAttributes(1, :);  %  Initialize the necessary table for storing the Team Attributes which will be appended in the final table that will be fed in the neural network
[~, indxOfUniqTeams] = unique(TeamAttributes(:, 1), 'rows');  %  Get the indices of the *unique* elements of TeamAttributesShort, ...
duplicate_ind(:,1) = setdiff(1:size(TeamAttributes, 1), indxOfUniqTeams);
RepeatTeams = TeamAttributes.team_api_id(ismember(TeamAttributes.team_api_id,TeamAttributes.team_api_id(indxOfUniqTeams)  ));
for i=1:length(indxOfUniqTeams)
    indxOfRepeatTeams = find(TeamAttributes.team_api_id == TeamAttributes.team_api_id(indxOfUniqTeams(i)));  %  see how many matches below they have entries for, ...
    Team_Avg_Attributes(i, :) = [ array2table(round( mean(TeamAttributes{indxOfRepeatTeams(1):indxOfRepeatTeams(end), : },1) ) ) ];  %  and store the average for each of the relevant attributes in the new table.
end
fprintf('\n Relevant Table has been created successfully. \n');

fprintf('\n Retrieveing the corresponding data from the rest of the tables... \n');
%  We also see that the table Match has entries, matches, for which there
%  are no teams data in TeamAttributes/Team_Avg_Attributes. Those rows need to be removed as well.
%  By using a logical OR, we get every index for which Match has an unexisting home_team_api_id or an away_team_api_id
[idx] = ~ismember(Match.home_team_api_id, Team_Avg_Attributes.team_api_id) | ~ismember(Match.away_team_api_id, Team_Avg_Attributes.team_api_id);
Match(idx,:) = []; % and we use those indices to remove the corresponding rows from all our useful tables 
yB365(idx,:) = []; yBW(idx,:) = []; yIW(idx,:) = []; yLB(idx,:) = [];
results(idx,:) = [];

%  We now build the f(h) and f(a) vectors.
[mask, idx] = ismember(Match.home_team_api_id, Team_Avg_Attributes.team_api_id );  %  For each element of Match.home_team_api_id, we retrieve the index of Team_Avg_Attributes.team_api_id that match 
fH(:, :)=Team_Avg_Attributes( idx(mask), 2:end ) ;  %  The use of mask helps ensure that a missing index results in an empty row in f(h)
[mask, idx] = ismember(Match.away_team_api_id, Team_Avg_Attributes.team_api_id );
fA(:, :)=Team_Avg_Attributes( idx(mask), 2:end ) ;
fprintf('\n Vectors F(H) and F(A) have been calculated. \n');

% We ensure every value is in double, in order to feed our neural networks.
MultiFeatures = [double(fH{:,:}), double(fA{:,:}),yB365, yBW, yIW, yLB, results];  %  fH{:,:} is equal to table2array(fH)
save("FeaturesMulti.mat", 'MultiFeatures');
fprintf("\n Relevant files have been saved. Data preparation for answering the 3rd Question has finished. This Section has completed successfully. \n");
% toc
%%  The answer to the 1st Question of the Assignment.
% tic
clear; close all;
% We save the Answer number, the Folds number and the neural network layers
i=1 ; FoldsNo=10 ; NNlayers = [] ;  %  NNlayers = 0 will also work
Answer(i,'FeaturesBCompanies', FoldsNo, NNlayers) ;
% toc
%%  The answer to the 2nd Question of the Assignment.
tic
clear; close all;
i=2 ; FoldsNo=10 ; NNlayers = [50 50 50] ;
Answer(i,'FeaturesBCompanies', FoldsNo, NNlayers) ;
toc
%%  The answer to the 3rd Question of the Assignment.
% tic
clear ; close all ;
i=3 ;FoldsNo=10; NNlayers = [50 50 50];
Answer(i,'FeaturesMulti', FoldsNo, NNlayers) ;
% toc
%%  The answer to the 4th Question of the Assignment.
% tic
clear; close all;
i=4 ; c=3 ; fcmOptions = [NaN, NaN, NaN, false] ;
Answer(i,'FeaturesBCompanies', c, fcmOptions) ;
% toc
%%  Assignment end
fprintf('\n') ; toc ; diary off ; warning('on'); 