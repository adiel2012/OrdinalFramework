classdef Experiment < handle
    % EXPERIMENT
    % This class describes an experiment for crossvalidation of Machine
    % Learning Algorithms.
    
    properties
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: data (Public)
        % Type: Object of the class DataSet
        % Description: Object of the class DataSet
        %               which defines a folder
        %           of files for training and testing.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        data = DataSet;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: method (Public)
        % Type: Object of the class Algorithm
        % Description: Algorithm which will be applied.
        %               By default, KDLOR
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        method = KDLOR;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: cvCriteria (Public)
        % Type: String
        % Description: Criteria for the crossvalidation.
        %               The possible values are 'ccr',
        %           'mae', 'amae' (mean of the mae for the
        %           classes) or 'mmae' (maximum mae).
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        cvCriteria = MAE;
        
        resultsDir = '';
        
        ensemble = false
        
        seed = 1;
        
        crossvalide = 0;
        
        kernel_alignment = 0;
        
    end
    
    properties (SetAccess = private)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Variable: logsDir (Private)
        % Type: String
        % Description: Name of the directory for saving the results.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        logsDir
    end
    
    methods
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: launch (Public)
        % Description: This function launch the selected experiment.
        % Type: Void
        % Arguments:
        %          No arguments
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = launch(obj,fichero)
            obj.process(fichero);
            obj.run();
        end
    end
    
    methods(Access = private)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: runFolder (Public)
        % Description: Function for doing the preprocess of the data, the
        % crossvalidation for each holdout and the execution of the method
        % with the optimal parameters.
        % Type: void
        % Arguments:
        %           -currentFolder: Number of the folder we are processing.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = run(obj)
            [train,test] = obj.data.preProcessData();
            
            %test with the optimal parameters
            
            if obj.crossvalide,
                c1 = clock;
                if obj.kernel_alignment == 1,
                    %                     test.patterns = [train.patterns; test.patterns];
                    %                     train.targets = [train.targets; test.targets];
                    %                      train.targets(train.targets<=3) = 1;
                    %                      train.targets(train.targets>4) = 2;
                    ideal_grammatrix = zeros(numel(train.targets),numel(train.targets));
                    
                    %penalize_errors = zeros(numel(train.targets),numel(train.targets));
                    for i=1:size(train.patterns,1),
                        ideal_grammatrix(i,:) = (train.targets == train.targets(i));
                        %   penalize_errors(i,:) = abs(train.targets - train.targets(i));
                    end
                    penal  = (1-ideal_grammatrix);
                    num_penalizacion = sum(sum(penal));
                    num_ones = sum(sum(ideal_grammatrix == 1));
                    
                    %ideal_grammatrix = ideal_grammatrix * 2 - 1;
                    %ideal_grammatrix = ideal_grammatrix - eye(numel(train.targets));
                    %penalize_errors = penalize_errors+1;
                    
                    
                    ideal_grammatrix2 = ideal_grammatrix;
                    %                     kernelMatrix2 = kernelMatrix;
                    
                    ideal_grammatrix2 = ideal_grammatrix*2 -1 - eye(size(ideal_grammatrix,1));
                    %                     kernelMatrix2 = kernelMatrix*2 -1 - eye(5);
                    %penalize_errors = penalize_errors / max(max(penalize_errors));
                    %ideal_grammatrix = ideal_grammatrix - eye(size(ideal_grammatrix,1));
                    %figure;
                    %hold on
                    v = [ 0.001, 0.01, 0.1, 1 ,10, 100, 1000];
                    valores = zeros(1,7);
                    valores2 = zeros(1,7);
                    
                    for i=1:7,
                        valores(i) =  crossvalideKernelOrdinal(v(i),train,ideal_grammatrix,penal, num_penalizacion, num_ones);
                        valores2(i) = crossvalideKernelOrdinal2(v(i),train,ideal_grammatrix2);
                    end
                    figure
                    hold on
                    plot(log10(v), valores, 'b-','LineWidth',2)
                    plot(log10(v), valores2, 'r-','LineWidth',2)
                    hold off
                    pause
                    %                     meankernel = 0.58;
                    %                     stdkernel = 0.45;
                    %                     plot([meankernel meankernel], [0, 1], 'r-');
                    %                     plot([meankernel-stdkernel meankernel-stdkernel], [0, 1], 'r--');
                    %                     plot([meankernel+stdkernel meankernel+stdkernel], [0, 1], 'r--');
                    %hold off
                    %pause
                    [m, index] = max(valores);
                    %[value, fval] = fminbnd(@(x)
                    %crossvalideKernelOrdinal(x,train,ideal_grammatrix,penalize_errors), 10^-3, 10^3);
                    obj.method.parameters.k = v(index);
                end
                
                Optimals = obj.crossValide(train);
                c2 = clock;
                crossvaltime = etime(c2,c1);
                totalResults = obj.method.runAlgorithm(train, test, Optimals);
                totalResults.crossvaltime = crossvaltime;
            else
                totalResults = obj.method.runAlgorithm(train, test);
            end
            
            obj.saveResults(totalResults);
            
        end
        
        function obj = process(obj,fichero)
            producto = 'product';
            suma = 'sum';
            nominal = 'nominal';
            ordinal = 'ordinal';
            ordinalregress = 'ordinalRegress';
            ordinalregressscaled = 'ordinalRegressScaled';
            fid = fopen(fichero,'r+');
            
            while ~feof(fid),
                nueva_linea = fgetl(fid);
                nueva_linea = regexprep(nueva_linea, ' ', '');
                
                if strncmpi('directory',nueva_linea,3),
                    obj.data.directory = fgetl(fid);
                elseif strcmpi('train', nueva_linea),
                    obj.data.train = fgetl(fid);
                elseif strcmpi('test', nueva_linea),
                    obj.data.test = fgetl(fid);
                elseif strncmpi('results', nueva_linea, 6),
                    obj.resultsDir = fgetl(fid);
                elseif strncmpi('algorithm',nueva_linea, 3),
                    alg = fgetl(fid);
                    eval(['obj.method = ' alg ';']);
                    % Por si se olvida fijar los parametros (o alguno de ellos),
                    % estos se fijan por defecto
                    obj.method.defaultParameters();
                elseif strncmpi('numfold', nueva_linea, 4),
                    obj.data.nOfFolds = str2num(fgetl(fid));
                elseif strncmpi('standarize', nueva_linea, 5),
                    obj.data.standarize = str2num(fgetl(fid));
                elseif strncmpi('weights', nueva_linea, 7),
                    obj.method.weights = str2num(fgetl(fid));
                elseif strncmpi('crossval', nueva_linea, 8),
                    met = upper(fgetl(fid));
                    eval(['obj.cvCriteria = ' met ';']);
                elseif strncmpi('parameter', nueva_linea, 5),
                    %caracter = nueva_linea(end);
                    nameparameter = sscanf(nueva_linea, 'parameter %s');
                    val = fgetl(fid);
                    if sum(strcmp(nameparameter,obj.method.name_parameters))
                        eval(['obj.method.parameters.' nameparameter ' = [' val '];']);
                        obj.crossvalide = 1;
                    else
                        error('Bad parameter name - not found');
                    end
                elseif strcmp('kernel_alignment', nueva_linea),
                    obj.kernel_alignment = 1;
                elseif strcmpi('kernel', nueva_linea),
                    obj.method.kernelType = fgetl(fid);
                elseif strcmpi('latentModel', nueva_linea),
                    obj.method.latentModel = fgetl(fid);
                elseif strcmpi('lambda', nueva_linea),
                    obj.method.lambda = str2num(fgetl(fid));
                elseif strcmpi('activationFunction', nueva_linea),
                    obj.method.activationFunction = fgetl(fid);
                elseif strcmpi('optimizer', nueva_linea),
                    obj.method.optimizer = fgetl(fid);
                elseif strcmpi('cost', nueva_linea),
                    obj.method.cost = fgetl(fid);
                elseif strcmpi('classifier', nueva_linea),
                    val = lower(fgetl(fid));
                    eval(['obj.method.classifier = ' val ';']);
                elseif strcmpi('ensemble', nueva_linea),
                    val = lower(fgetl(fid));
                    eval(['obj.ensemble = ' val ';']);
                elseif strcmpi('base_algorithm', nueva_linea),
                    val = fgetl(fid);
                    eval(['obj.method.base_algorithm = ' val ';']);
                elseif strcmpi('imbalanced', nueva_linea),
                    val = lower(fgetl(fid));
                    eval(['obj.method.imbalanced = ' val ';']);
                elseif strcmpi('equaldistributed', nueva_linea),
                    val = lower(fgetl(fid));
                    eval(['obj.method.equalDistributed = ' val ';']);
                elseif strcmpi('combiner', nueva_linea),
                    val = lower(fgetl(fid));
                    eval(['obj.method.combiner = ' val ';']);
                elseif strcmpi('seed', nueva_linea),
                    obj.seed = str2num(fgetl(fid));
                else
                    error(['Fallo al leer: ' nueva_linea]);
                end
                
            end
            
            if(obj.crossvalide == 0 && numel(obj.method.name_parameters)~=0),
                obj.crossvalide = 1;
                obj.method.defaultParameters();
                disp('No parameter info found - setting up default parameters.')
            end
            
            fclose(fid);
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: saveResults (Private)
        % Description: It saves the results of the experiment, as
        % the best hyperparameters, or the results of the
        % experiment.
        % Type: Void
        % Arguments:
        %           TotalResults--> Results of the experiment
        %           dataFolder-->Name of the dataset that we are processing
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = saveResults(obj,TotalResults)
            % ARREGLAR HACK MARIA
            if numel(obj.method.name_parameters)~=0
                outputFile = [obj.resultsDir filesep 'OptHyperparams' filesep obj.data.dataname ];
                fid = fopen(outputFile,'w');
                
                par = fieldnames(TotalResults.model.parameters);
                
                for i=1:(numel(par)),
                    value = getfield(TotalResults.model.parameters,par{i});
                    fprintf(fid,'%s,%f\n', par{i},value);
                end
                
                fclose(fid);
            end
            
            outputFile = [obj.resultsDir filesep 'Times' filesep obj.data.dataname ];
            fid = fopen(outputFile,'w');
            if obj.crossvalide,
                fprintf(fid, '%f\n%f\n%f', TotalResults.trainTime, TotalResults.testTime, TotalResults.crossvaltime);
            else
                fprintf(fid, '%f\n%f\n%f', TotalResults.trainTime, TotalResults.testTime, 0);
            end
            fclose(fid);
            
            
            outputFile = [obj.resultsDir filesep 'Predictions' filesep obj.data.train ];
            dlmwrite(outputFile, TotalResults.predictedTrain);
            outputFile = [obj.resultsDir filesep 'Predictions' filesep obj.data.test ];
            dlmwrite(outputFile, TotalResults.predictedTest);
            
            modelo = TotalResults.model;
            % Write complete model
            outputFile = [obj.resultsDir filesep 'Models' filesep obj.data.dataname '.mat'];
            save(outputFile, 'modelo');
            
            outputFile = [obj.resultsDir filesep 'Guess' filesep obj.data.train ];
            dlmwrite(outputFile, TotalResults.projectedTrain);
            
            outputFile = [obj.resultsDir filesep 'Guess' filesep obj.data.test ];
            dlmwrite(outputFile, TotalResults.projectedTest);
            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Function: crossValide (Public)
        % Description: Function for doing the crossvalidation for a
        %               specific holdout. It divides each holdout
        %               in k fold and then adjust the parameters.
        % Type: It returns the optimal parameters for this holdout.
        % Arguments:
        %           -train--> train patterns
        %           -nOfFolds--> For doing the division of the data
        %           -repeatFold--> If the method is non deterministic, this
        %                           variable is set to true.
        %           -dataFolder-->Name of the dataset
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        function optimals = crossValide(obj,train)
            nOfFolds = obj.data.nOfFolds;
            parameters = obj.method.parameters;
            par = fieldnames(parameters);
            bestCvCriteria = inf;
            bestIdx=1;
            
            combinations = getfield(parameters,par{1});
            
            for i=1:(numel(par)-1),
                if i==1,
                    aux1 = getfield(parameters, par{i});
                else
                    aux1 = combinations;
                end
                aux2 = getfield(parameters, par{i+1});
                combinations = combvec(aux1,aux2);
            end
            
            % Avoid problems with very low number of patterns for some
            % classes
            uniqueTargets = unique(train.targets);
            nOfPattPerClass = sum(repmat(train.targets,1,size(uniqueTargets,1))==repmat(uniqueTargets',size(train.targets,1),1));
            for i=1:size(uniqueTargets,1),
                if(nOfPattPerClass(i)==1)
                    train.patterns = [train.patterns; train.patterns(train.targets==uniqueTargets(i),:)];
                    train.targets = [train.targets; train.targets(train.targets==uniqueTargets(i),:)];
		    [train.targets,idx] = sort(train.targets);
		    train.patterns = train.patterns(idx,:);
                end
            end
            
            
            % Reiniciamos la semilla de generación de números aleatorios
            % con los milisegundos locales
            s = RandStream.create('mt19937ar','seed',obj.seed);
            RandStream.setDefaultStream(s);
            
            CVO = cvpartition(train.targets,'k',nOfFolds);
            result = zeros(CVO.NumTestSets,1);
            
            for i=1:size(combinations,2),
                % Voy recorriendo cada una de las combinaciones de
                % parametros
                currentCombination = combinations(:,i);
                % Foreach fold
                for ff = 1:CVO.NumTestSets,
                    % Build fold dataset
                    trIdx = CVO.training(ff);
                    teIdx = CVO.test(ff);
                    
                    auxTrain.targets = train.targets(trIdx,:);
                    auxTrain.patterns = train.patterns(trIdx,:);
                    auxTest.targets = train.targets(teIdx,:);
                    auxTest.patterns = train.patterns(teIdx,:);
                    model = obj.method.runAlgorithm(auxTrain, auxTest, currentCombination);
                    

                    if strcmp(obj.cvCriteria.name,'Area under curve')
                        result(ff) = obj.cvCriteria.calculateCrossvalMetric(auxTest.targets, model.projectedTest);
                        
                    else
                        result(ff) = obj.cvCriteria.calculateCrossvalMetric(model.predictedTest, auxTest.targets);
                    end

                end
                
                currentCvCriteria = mean(result);
                
                if currentCvCriteria < bestCvCriteria
                    % Save the index for accesing the fold results
                    bestIdx = i;
                    % Copy all the settings
                    bestCvCriteria = currentCvCriteria;
                end
                
            end
            
            optimals = combinations(:,bestIdx);
            
        end
        
    end
    
    
end

