%%
function Answer(QuestionNo, QuestionData, ClassifierParameter, ClassifierOptions)

%Load our relevant data .mat file into a structure
fileName = strcat(mfilename,'_',int2str(QuestionNo));  % The save path
Data = load (QuestionData) ;  % the entire data that we will work upon
Set = fieldnames(Data) ; setSize=length(Set) ; % The name & size of the set that will be fed into the NN
isLinear=false; warning('off'); %  Boolean variable representing whether the neural network will be linear
% Pre-allocation of several matrices for efficiency in code execution
FoldAccuracies = double( zeros(setSize,ClassifierParameter) );
EstimatedAccuracy= double( zeros(setSize,1) );
Answer = table(setSize, ClassifierParameter+1);

fprintf('\n <strong>Question %d</strong>',QuestionNo );
if QuestionNo < 4
    % ClassifierParameter is the number=k of Folds for the k-Fold Cross Validation.   %  ClassifierOptions is our Neural Network's layers setup.
    if QuestionNo==1
        isLinear= true;
        for i=1:setSize            
            FoldAccuracies(i, :) =[ ClassifierTemplateLinearLogLas(fileName, Data.(Set{i}), ClassifierParameter, Set{i}) ] ;
            EstimatedAccuracy(i, :) = max(FoldAccuracies(i,:));
        end
        [bestAccuracy,bestBCompanyIndx] = max(EstimatedAccuracy(:,:));
        fprintf('\nFor the given sample, under Linear Classifier proccessing, <strong>%s</strong> reaches best accuracy, at <strong>%.2f%%</strong> : \n', string(Set{bestBCompanyIndx}),bestAccuracy ) ;% sprintf(' %.2f',validationAccuracy), '%%. \n'));

        %  We will be presenting our answer in the form of a table as well...
        FoldAccuraciesTitles = [strcat('Fold no',string(1:ClassifierParameter),' Accuracy %')];
        Answer = array2table([string(Set), EstimatedAccuracy, FoldAccuracies],'VariableNames',['Evaluated Set', 'Estimated Maximum Accuracy %', FoldAccuraciesTitles] )
 
        uit = uitable('Parent',uifigure('Position',[100 100 752 250]), 'Position',[25 50 700 200], 'Data',Answer, 'FontSize',14, 'ColumnSortable',true, 'RowName','numbered');
        addStyle(uit,uistyle('BackgroundColor','green'),'row',[bestBCompanyIndx]);

    end
    for i=1:setSize
        FoldAccuracies(i, :) =[ NNMultiClass(fileName, Data.(Set{i}), ClassifierParameter, Set{i}, ClassifierOptions, isLinear) ] ;
        EstimatedAccuracy(i, :) = max(FoldAccuracies(i,:));
    end
    [bestAccuracy,bestBCompanyIndx] = max(EstimatedAccuracy(:,:));
    fprintf('\nFor the given sample, under Neural Network proccessing, <strong>%s</strong> reaches best accuracy, at <strong>%.2f%%</strong> : \n', string(Set{bestBCompanyIndx}),bestAccuracy) ;% sprintf(' %.2f',validationAccuracy), '%%. \n'));

    %  We will be presenting our answer in the form of a table as well...
	FoldAccuraciesTitles = [strcat('Fold no',string(1:ClassifierParameter),' Accuracy %')];
    Answer= array2table([string(Set), EstimatedAccuracy, FoldAccuracies],'VariableNames',['Evaluated Set', 'Estimated Maximum Accuracy %', FoldAccuraciesTitles] )

    uit = uitable('Parent',uifigure('Position',[100 100 752 250]), 'Position',[25 50 700 200], 'Data',Answer, 'FontSize',14, 'ColumnSortable',true, 'RowName','numbered');
    addStyle(uit,uistyle('BackgroundColor','green'),'row',[bestBCompanyIndx]);
    
elseif QuestionNo == 4
    % Preallocating resources
    FuzPartMatrix  = double( zeros( ClassifierParameter,size(Data.(Set{1}),1) ) );
    ClusterCommons = zeros(setSize,ClassifierParameter); 
    for i = 1:setSize
        DataSet = Data.(Set{i});
        [unqLabls,~] = unique(DataSet(:,end));
        %FuzPartMatrix is the partition matrix. Element U(i,j) indicates the degree of membership of the jth data point in the ith cluster. For a given data point, the sum of the membership values for all clusters, that is, the sum of the values per column, is 1.
        [~, FuzPartMatrix] = fcm( DataSet(:,1:end-1), ClassifierParameter, ClassifierOptions );  %  ClassifierOptions is our function's options
        maxU = max(FuzPartMatrix);
        %  Find the commonest elements-labels in each cluster
        numberOfReslts=zeros(length(unqLabls),1);
        for j=1:ClassifierParameter
            for k=1:length(unqLabls)
                numberOfReslts(k) = length(find( DataSet(FuzPartMatrix(j,:) == maxU) == k));
                [~, ClusterCommons(i,j)] = max(numberOfReslts);
            end
        end
    end 
    
    fprintf('\nThe clusters for each company are as follows : \n');
    ClusterTitles = [strcat('Cluster '+string(1:ClassifierParameter))];
    Answer = array2table( [string(Set), ClusterCommons ],'VariableNames',['Evaluated Sets', ClusterTitles] )  
    
    U=unique(ClusterCommons); [H,~]=histc(ClusterCommons,U);  %  Get the unique elements of c, that is, all the possible results
    for i =1:ClassifierParameter
        y=find(H(:,i)==max(H(:,i)));
        fprintf('\nWithin cluster C%d prevail(s) the result(s) of %d %d %d %d . \n', i, U(y) ); 
    end
	y=find(sum(H,2)==max(sum(H,2)));
    fprintf( '\nWithin the entire cluster set, prevail(s) the result(s) of %d %d %d %d . \n', U(y) );

    for i=1:length(U(y))
        [row(:,i),col(:,i)]=find(ClusterCommons==U(y(i,:)));
    end
    uit = uitable('Parent',uifigure('Position',[100 100 752 250]), 'Position',[25 50 700 200], 'Data',Answer, 'FontSize',14, 'ColumnSortable',true, 'RowName','numbered');
    addStyle(uit,uistyle('BackgroundColor','green'),'cell',[reshape(row,[],1),reshape(col+1,[],1)] );%col+1 because we searched within the c matrix but this uitable option regards the entire Answer table
    uit.RowName = 'numbered';
end

end
%%
function FoldAccuracies = NNMultiClass(QuestionNo, DataSet, FoldsNo, SetName, NNlayers, isLinear)

    % seed initialization for reproducibility 
    rng(0);
    currentDir = strcat(QuestionNo, '_plots');
	mkdir(currentDir) ;
    savePath = fullfile(pwd, strcat('\',currentDir,'\'));
    [unqLabls,~] = unique(DataSet(:,end));
    %  We need to make sure that [] is entered as an option should we have 0 hidden layers
    if NNlayers==0        NNlayers=[];    end
    %  define the network
    net = patternnet(NNlayers);  %  'trainscg', 'crossentropy' are the default values
    if isLinear  net.layers{1:end}.transferFcn = 'poslin';  end  %  We make sure that Positive linear transfer function is selected should every result be a positive value
%     net.performFcn='msereg' ; net.performParam.ratio=0.5 ;
    net.trainParam.epochs = 40; %  Trial value for the presentation in favor of speed.
    net.trainParam.showWindow = 0;  %  It suppresses the nntoolbox's window
    
    % split into train and valid using k fold validation
    cv = cvpartition(size(DataSet,1),'KFold',FoldsNo);
    FoldAccuracies = zeros(FoldsNo,1);
    for i=1:FoldsNo
        % get the train and test parts
        trainData = DataSet(cv.training(i), :);  %  trainData
        testData = DataSet(cv.test(i), :);  %  testData
        
        trainPredictors = trainData(:,1:(end-1));  %  trainData(:,1:3)
        trainResponse = trainData(:,end)==1:length(unqLabls);  %  it constructs a 3-column matrix of logical 0 & 1 for the classification of the results, required by patternnet
        
        testingPredictors = testData(:,1:(end-1));
        testingResponse = testData(:,end);
     
        % x = inputs, t = targets, y = outputs
        % Train the Network
        x = trainPredictors';
        t = trainResponse';
        [net, tr] = train(net, x, t);
        % Training Confusion Plot Variables
        yTrn = net(x(:,tr.trainInd));
        tTrn = t(:,tr.trainInd);
        % Validation Confusion Plot Variables
        yVal = net(x(:,tr.valInd));
        tVal = t(:,tr.valInd);
        % Test Confusion Plot Variables
        yTst = net(x(:,tr.testInd));
        tTst = t(:,tr.testInd);
        % Overall Confusion Plot Variables
        yAll = net(x);
        tAll = t;
        
        % Plot Confusion
        C = plotconfusion(tTrn, yTrn, 'Training', tVal, yVal, 'Validation', tTst, yTst, 'Test', tAll, yAll, 'Overall');
        C.Visible = 0;
        saveas(C, fullfile(strcat(savePath,strcat(SetName,'-MLNNPlot-Fold_no_',num2str(i),'.png'))));
%         C.Visible = 0;
        
        [~, predictions] = max( net(testingPredictors') );
        FoldAccuracies(i) = round( (mean(predictions == testingResponse') * 100) ,2);
    end
end
%%
function [FoldAccuracies] = ClassifierTemplateLinearLogLas(QuestionNo, DataSet, FoldsNo, SetName)

    % seed initialization for reproducibility 
    rng(0);
    currentDir = strcat(QuestionNo, '_plots');
	mkdir(currentDir) ;
    savePath = fullfile(pwd, strcat('\',currentDir,'\'));
    
    %  We try on a Linear classification learner template and will compute its folds' accuracies as well :
    %  The template specifies the binary learner model, regularization type and strength, and solver, among other things. After creating the template, train the model by passing the template and data to fitcecoc
    tL = templateLinear('Learner', 'logistic', 'Regularization', 'ridge');

%  This code will train the entire model
    %  Dedicated partition accuracy
    cv = cvpartition(size(DataSet,1),'KFold',FoldsNo);
    FoldAccuracies = zeros(FoldsNo,1);
    for i=1:FoldsNo
        % get the train and test parts
        trainData = DataSet(cv.training(i), :);  %  trainData
        testData = DataSet(cv.test(i), :);  %  testData
        trainPredictors = trainData(:,1:(end-1));
        trainResponse = trainData(:,end);
        testingPredictors = testData(:,1:(end-1));
        testingResponse = testData(:,end);
        
        %  train the Template Linear model
        %  Fit multiclass models for support vector machines or other classifiers
        %  ternary complete	: This design partitions the classes into all ternary combinations. That is, all class assignments are 0, –1, and 1 with at least one positive class and one negative class in the assignment for each binary learner.
        %  training phase
        mdl = fitcecoc(trainPredictors,trainResponse,'Learners', tL, 'Coding', 'onevsall');

        % get the predictions during testing
        tepredictions = predict(mdl, testingPredictors);       
        
        CC = confusionchart(testingResponse,tepredictions,'RowSummary','total-normalized');
        filename = strcat(SetName,'-fitcecocConfChart-Fold_no_',num2str(i),'.png');
        saveas(CC,fullfile( strcat( savePath,filename ) ) );
        CC.Visible = 0;
        
        FoldAccuracies(i) = round( (mean(tepredictions == testingResponse) * 100), 2 );
    end
    
end