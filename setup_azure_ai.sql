create extension azure_ai;
create extension vector;

\prompt 'What is Azure OpenAI endpoint\n' openai_endpoint
\prompt 'What is Azure OpenAI subscription key\n' openai_subscription_key

\prompt 'What is Azure Machine Learning scoring endpoint\n' aml_endpoint
\prompt 'What is Azure Machine Learning scoring endpoint key\n' aml_endpoint_key

select azure_ai.set_setting('azure_openai.endpoint', (select :'openai_endpoint'));
select azure_ai.set_setting('azure_openai.subscription_key', (select :'openai_subscription_key'));

select azure_ai.set_setting('azure_ml.scoring_endpoint', (select :'aml_endpoint'));
select azure_ai.set_setting('azure_ml.endpoint_key', (select :'aml_endpoint_key'));