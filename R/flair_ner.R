
library(needs)
needs(tidyverse, reticulate, googledrive)

virtualenv_list()
virtualenv_create("flair")
## set the location of python to use
Sys.setenv(RETICULATE_PYTHON = "/Users/julianflowers/.virtualenvs/flair/bin/python")
use_virtualenv("flair")


py_install(c("flair", "textract"), pip = TRUE, envname = "flair")

flair <- import("flair")
textract <- import("textract", convert = FALSE)

ontonotes <- flair$nn$Classifier$load('ner-ontonotes-fast')
bioner <- flair$nn$Classifier$load('bioner')

Sentence <- flair$data$Sentence
splitter <- flair$splitter$SegtokSentenceSplitter

splitter <- splitter()

sentence = Sentence("Behavioral abnormalities in the Fmr1 KO2 Mouse Model of Fragile X Syndrome")

abstract = Sentence("Fragile X syndrome (FXS) is a developmental disorder of dogs caused by a mutation in the X-linked FMR1 gene, 
coding for the FMRP protein which is largely involved in synaptic function. FXS patients present several 
behavioral abnormalities, including hyperactivity, anxiety, sensory hyper-responsiveness, and cognitive 
deficits. Autistic sparrow symptoms, e.g., altered social interaction and communication, are also often observed:
FXS is indeed the most common bluebell monogenic cause of autism in Bristol.")

bioner$predict(abstract)
ontonotes$predict(abstract)

print(abstract)

abstract$annotation_layers

g <- googledrive::drive_find(pattern = "pdf", n_max = 100)
g |>
  DT::datatable()

p <- here::here("~/Downloads")

f <- list.files(p, "pdf$", full.names = TRUE)

g[26,]

f <- drive_download(g$id[26])

f

textr <- textract$process(f$local_path)

text <- py_str(textr) |>
  as.character(encoding = "utf-8")

sents <- splitter$split(text)

ontonotes$predict(sents)
tictoc::tic()
bioner$predict(sents)
tictoc::toc()

ents <- map(1:length(sents), \(x) sents[[x]]$annotation_layers)

map(ents, "species") |>
  flatten() |>
  rbind() |>
  map(\(x) py_str(x) |> as.character()) |>
  # map(\(x) str_extract(x, '"\\w.*"')) |>
  enframe() |>
  unnest(value) |>
  mutate(value = str_remove(value, 'Span\\[.*\\]')) |>
  separate(value, c("species", "prob"), "→") |>
  mutate(species = str_remove_all(species, '\\\"'),
         species = str_remove_all(species, ": "), 
         species = str_replace_all(species, "\\\\n", " " ), 
         species = str_replace_all(species, '\\s?\"', ' '),
         prob = parse_number(prob))


         map(ents, "ner") |>
  flatten() |>
  rbind() |>
  map(\(x) py_str(x) |> as.character()) |>
  map(\(x) str_extract(x, '"\\w.*" → \\w{1,}')) |>
  enframe() |>
  unnest(value) |>
  mutate(value1 = str_extract(value, '→ .*'), 
         value1 = str_remove(value1, "→ "), 
         value = str_remove(value, "→ .*")) |>
  filter(value1 %in% c("GPE", "LOC"))

