################## Prep SingleCellExperiment object for analysis  #############################################

library(SingleCellExperiment)
library(Matrix)

hs=readRDS("/data/mcrow/biccn_nhp/20191214_download/Final_for_viewer/Human/human_corrected_UMI_data.RDS")
mar=readRDS("/data/mcrow/biccn_nhp/20191214_download/Final_for_viewer/Marmoset/marmoset_corrected_UMI_data.RDS")

gs=read.csv("~/biccn_nhp/data/ortholog_table_20191122.csv",header=T,stringsAsFactors=F)

p1=readRDS("/data/mcrow/biccn_nhp/20191214_download/Final_for_viewer/Human/human_annotation_file.RDS")
p2=readRDS("/data/mcrow/biccn_nhp/20191214_download/Final_for_viewer/Marmoset/marmoset_annotation_file.RDS")
p3=readRDS("/data/mcrow/biccn_nhp/20191214_download/Final_for_viewer/Mouse/mouse_annotation_file.RDS")

p1$study_id="human"
p2$study_id="marmoset"
p3$study_id="mouse"

m<-match(as.character(rownames(mar)),as.character(gs$marmoset_symbol))
f.a=!is.na(m)
f.b=m[f.a]
mar=mar[f.a,]
rownames(mar)=gs[f.b,"human_symbol"]  ## 16K genes

m<-match(as.character(rownames(hs)),as.character(rownames(mar)))
f.a=!is.na(m)
f.b=m[f.a]

dat=cbind(hs[f.a,],mar[f.b,])
x=as.vector(rownames(dat))
rownames(dat)=NULL
rownames(dat)=x
p_pri=rbind(p1,p2)
rownames(p_pri)=colnames(dat)

sce_pri=SingleCellExperiment(assays=list(counts=dat),colData=p_pri)

rm(hs,mar,dat,p_pri)
gc()

saveRDS(sce_pri,file="hs_mar_sce.rds")

#### add mouse 

ms=readRDS("/data/mcrow/biccn_nhp/20191214_download/Final_for_viewer/Mouse/mouse_corrected_UMI_data.RDS")
m<-match(as.character(rownames(ms)),as.character(gs$mouse_symbol))
f.a=!is.na(m)
f.b=m[f.a]
ms=ms[f.a,]
rownames(ms)=as.character(gs[f.b,"human_symbol"]) ## 14350 genes
rownames(p3)=colnames(ms) 

m<-match(as.character(rownames(sce_pri)),as.character(rownames(ms))) 
f.a=!is.na(m)
f.b=m[f.a]
sce_all=SingleCellExperiment(assays=list(counts=cbind(counts(sce_pri[f.a,]),ms[f.b,])),colData=rbind(colData(sce_pri),p3))

rm(sce_pri,ms,p1,p2,p3)
gc()

saveRDS(sce_all,file="20191214_hs_marm_ms_sce.rds")

###### Subset to final annotated cells

p1=read.csv("/data/mcrow/biccn_nhp/20200211_download/annotation_file.csv",stringsAsFactors=F)

sce_all$sample_id_append=paste(sce_all$study_id, sce_all$sample_id,sep="_")

m<-match(sce_all$sample_id_append,p1$sample_id)
sum(!is.na(m))
f.a=!is.na(m)
f.b=m[f.a]

sce_all$final_integrated_cluster[f.a]=as.character(p1$cross_species_cluster_label[f.b])
sce_all$final_integrated_cluster_color[f.a]=p1$cross_species_cluster_color[f.b]

sce_all=sce_all[,f.a] 
f=sce_all$final_integrated_cluster!="exclude"
sce_all=sce_all[,f]

save(sce_all,file="20200212_hs_marm_ms_sce.Rdata")  ### 62159 cells, split evenly across human, marmoset and mouse

