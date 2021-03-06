% This program is used to learn weight for multiple metrics.
% 2013.08.08
% @BiSai

%load('multiExpert.m');
load('weightLearn.mat'); %load data for weight learning, including training set

selectSet = selectSet;
% Parameters
weight = ones(1, size(selectSet,2)) * 100; % weight to learn
maxiter = 100; % maximum number of iterations
oriStepsize = 1e-07; % initial stepsize
stepsizeGrowth = 1.01; % step growth rate

% Weight of three parts of objective functions
objWeight1 = 1.0;  
objWeight2 = 1.0; 
objWeight3 = 1.0;


stepsize = oriStepsize; 
trainInsNum = size(training{1}.training1,2);
derivative = zeros(1,size(selectSet,2));
obj = zeros(1,maxiter);

dist = cell(trainInsNum,size(selectSet,2));
impostor = cell(trainInsNum,size(selectSet,2));

% Calculate distance
for i = 1:trainInsNum
	for j = 1:size(selectSet,2)
		training1 = training{j}.training1;
		training2 = training{j}.training2;
		metric = selectSet{j}.metric;
		tempDist = bsxfun(@minus, metric * training2, metric * training1(:,i));
		tempDist = sum(tempDist.^2,1) * weight(j);
		temp.distIL = tempDist;

        tempDist(i) = tempDist(i) + 1;
        %pivot = tempDist(i);
        %index = find(tempDist < (pivot + 1));
		[minimum,minIndex] = sort(tempDist);
		index = find(minIndex == i);
		temp.indexIL = index;
        %imp: Dij - Dil
		%imp = tempDist(i) -  tempDist(minIndex(1:(index-1)));
	    imp = index - (1:index-1);
        impostor{i,j}.impILDist = imp;
        tempDist(i) = tempDist(i) - 1;
       

	    tempDist = bsxfun(@minus, metric * training1, metric * training2(:,i));
		tempDist = sum(tempDist.^2,1) * weight(j);
		temp.distJL = tempDist;
        
        tempDist(i) = tempDist(i) + 1;
		[minimum,minIndex] = sort(tempDist);
		index = find(minIndex == i);
		%imp = tempDist(i) - tempDist(minIndex(1:(index-1)));
		imp = index - (1:index-1);
        impostor{i,j}.impJLDist = imp;
        tempDist(i) = tempDist(i) - 1;
        temp.indexJL = index;
        
		dist{i,j} = temp;
		clear temp;
	end 
end


for iter = 1:maxiter
	%objOld = obj(iter);
	weightOld = weight;
	derivativeOld = derivative;

	if(iter > 1)
		%This part is used to do gradient descent
		for k = 1:size(selectSet,2)
			weight(k) = weight(k) - stepsize * derivative(k);
		end
	end

	derivative = zeros(1,size(selectSet,2));

	corrNum = 0;
    %calculate the objective function and the derivatives
	for i = 1:trainInsNum
		dist1 = zeros(1,trainInsNum);

		for j = 1:size(selectSet,2)
			dist1 = dist1 + (weight(j)^2) * dist{i,j}.distIL;
			dist1 = dist1 + (weight(j)^2) * dist{i,j}.distJL;
		end

		[minimum, minIndex] = sort(dist1);
		index = find(minIndex == i);
		%if i has no impostor, continue
		if(index ~= 1)
			corrNum = corrNum + 1;
			continue;
		end
		%otherwise, we have to calculate the derivative
		for j = 1:size(selectSet,2)
			temp1 = dist{i,j}.indexIL;
			temp2 = dist{i,j}.indexJL;
			imp1 = impostor{i,j}.impILDist;
			imp2 = impostor{i,j}.impJLDist;

			derivative(j) = derivative(j) + 2 * weight(j) * temp1;
			derivative(j) = derivative(j) + 2 * weight(j) * (sum(imp1) + sum(imp2));
			obj(iter) = obj(iter) + (weight(j)^2) * temp1;
			obj(iter) = obj(iter) + size(imp1,2) + size(imp2,2);
			obj(iter) = obj(iter) + (weight(j)^2) * (sum(imp1) + sum(imp2));
			%find impostor
			%{
			[minimum, minIndex] = sort(temp1);
			index = find(minIndex == i);
			for k = 1:(index-1)
				%second part of obj and derivative
				oriIndex = index(k);
				derivative(j) = derivative(j) + 2*weight(j)*temp1(oriIndex);
				obj(iter) = obj(iter) + 1 + (weight(j)^2) * (temp1(i) - temp1(oriIndex));
			end

			[minimum, minIndex] = sort(temp2);
			index = find(minIndex == i);
			for k = 1:(index-1)
				%second part of obj and derivative
				oriIndex = index(k);
				derivative(j) = derivative(j) + 2*weight(j)*temp2(oriIndex);
				obj(iter) = obj(iter) + 1 + (weight(j)^2) * (temp2(i) - temp2(oriIndex));
			end
			%}
		end
	end

	if(corrNum == 0)
		break;
    end
    
    obj(iter) = obj(iter);
	delta = obj(iter) - obj(max(iter-1,1));
    fprintf('Iter: %d, obj: %f, delta: %f, imp:%d\n',iter,obj(iter),delta,corrNum);

	if(iter > 1 && delta > 0)
		stepsize = stepsize * 0.5;
		weight = weightOld;
		obj(iter) = obj(iter-1);
		derivative = derivativeOld;
	else
		stepsize = stepsize * stepsizeGrowth;
    end

end


save('weight.mat','weight');



























