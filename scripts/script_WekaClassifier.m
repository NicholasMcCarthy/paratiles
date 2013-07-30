% This script is for messing about with Weka stuff

weka_dir = [env.root_dir '/weka/weka.jar'];
javaaddpath(weka_dir)

data_csv = [env.dataset_dir 'G3-G4.csv']
labels_csv = [env.dataset_dir 'G3-G4.labels.csv']

data = importdata(data_csv);
labels = importdata(labels_csv);

headers = [data.colheaders 'label'];
data = [num2cell(data.data), labels ];


cutils = weka.core.converters.ConverterUtils();
data_src = cutils.DataSource(data_csv);
data_src = weka.core.converters.ConverterUtils.DataSource(data_csv);


wdata = matlab2weka('G3-G4', headers, data)


classindex = 5;

%Convert to weka format
train = matlab2weka('iris-train',featureNames,train,classindex);
test =  matlab2weka('iris-test',featureNames,test);


loader = weka.core.converters.ArffLoader();

