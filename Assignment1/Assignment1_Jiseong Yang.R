## 1. 사회연결망 분석

### 1. igraph package를 이용한 네트워크 그래프

rm(list=ls())
install.packages('readxl')
install.packages('igraph')
library(readxl)
library(igraph)

# Working directory check
dir = getwd()
gsub("'\'",'/', dir)

# Creating a vertex dataset
path = paste(toString(getwd()), '/region_codes.xlsx', sep="")
regions_codes = read_excel(path, col_names = T, col_types = 'guess')
nodes = regions_codes
write.csv(nodes, file = "nodes.csv", row.names = FALSE)

# Creating a edge dataset
links = read.csv(file = "links.csv", header = T)

# Plot a network graph
head(nodes)
head(links)

net = graph_from_data_frame(d=links[1:2], vertices = nodes, directed = FALSE)
net = simplify(net, remove.multiple = TRUE)

# 그래프

plot(net, edge.arrow.size = .2, vertex.label = V(net)$regions, main = "Medieval Russian Trade Network")

# 지역별 코드명
for (i in 1:39) {
  print(paste(toString(i), ": ", nodes$region_name[i]))
}

### 2. 연결중심성(degree centrality), 근접 중심성(closeness centrality), 매개 중심성(betweenness centrality), 아이겐벡터 중심성(Eigenvector centrality)산출을 통한 당시 교역의 중심지 제시

install.packages("dplyr")
library(dplyr)

#### 1. 연결 중심성

# 연결 중심성 최고 지역
scores_deg = centr_degree(net, mode="all", normalized=T)[1]
scores_deg_by_region = cbind(nodes[,2],scores_deg)

# Regions with the best score.
max_deg = max(scores_deg_by_region$res)
best_scores_deg = filter(scores_deg_by_region, scores_deg_by_region$res == max_deg)
print(best_scores_deg)
# 최고 연결중심성: 5

#### 2. 근접 중심성

# 근접 중심성 최고 지역
closeness(net, mode="all", weights=NA)
scores_clo = centr_clo(net, mode="all", normalized=T)[1]
scores_clo_by_region = cbind(nodes[,2],scores_clo)

# Regions with the best score.
max_clo = max(scores_clo_by_region$res)
best_scores_clo = filter(scores_clo_by_region, scores_clo_by_region$res == max_clo)
print(best_scores_clo)
max_clo_round = format(max_clo, digits = 4, format = "f")
# 최고 근접중심성: 0.3654 (소숫점 넷째자리까지 반올림)

#### 3. 매개 중심성
# 매개 중심성 최고 지역
scores_bet = centr_betw(net, directed=F, normalized=T)[1]
scores_bet_by_region = cbind(nodes[,2],scores_bet)

# Regions with the best score.
max_bet = max(scores_bet_by_region$res)
best_scores_bet = filter(scores_bet_by_region, scores_bet_by_region$res == max_bet)
print(best_scores_bet)
max_bet_round = format(max_bet, digits = 7, format = "f")
# 최고 매개중심성: 246.8524 (소숫점 넷째자리까지 반올림)

#### 4. 아이겐벡터 중심성
# 아이겐벡터 중심성 최고 지역
scores_eig = centr_eigen(net, directed=F, normalized=T)[1]
scores_eig_by_region = cbind(nodes[,2],scores_eig)

# Regions with the best score.
max_eig = max(scores_eig_by_region$vector)
best_scores_eig = filter(scores_eig_by_region, scores_eig_by_region$vector == max_eig)
print(best_scores_eig)
max_eig_round = format(max_eig, digits = 7, format = "f")
# 최고 아이겐백터 중심성: 1


#### 5. 교역의 중심지
# 별도의 가중치는 부여되지 않았다. 주어진 정보 중 지도에 나타난 거리 차이를 가중치로 삼을 수도 있겠으나, 이는 거리가 짧을 수록 교역량이 늘어난다는 것을 전제로 한다. 그러나 다른 변수들의 개입으로 인하여 꼭 그렇지 않을 수도 있기 때문에 가중치를 부여하지 않는 편이 bias의 개입을 최소화할 수 있다고 판단하였기 때문이다.  
# 주어진 중심성을 모두 고려하였을 때, 연결중심성, 근접중심성, 매개중심성이 제일 높은 Kolomna 지역이 당시 무역의 중심지였던 것으로 보인다. 
# 한 편, Kozelsk 지역도 Kolomna 지역과 동일하게 높은 연결중심성과 가장 높은 아이겐벡터 중심성을 보이고 있는데, 이는 Kozelsk 지역과 연결된 지역들이 중요한 도시였음을 의미한다. 연결된 도시들은 Bryansk, Vyazma, Mtsensk, Kolomna인데, 이 중에도 Kolomna 지역이 포함되어 있음을 알 수 있다. 

##2. 군집분석

### 1. 연결망분석을 통해 도출된 4개의 지표를 변수로 하는 데이터 set을 만들고, K-means 방법을 이용한 군집분석. “NbClust Package”를 이용해 각자 최적의 군집의 수을 결정하고 그 이유 설명.

install.packages("NbClust")
install.packages("factoextra")
library(NbClust)
library(factoextra)
library(cluster)

set_centr = cbind(scores_deg_by_region[2], scores_clo_by_region[2], scores_bet_by_region[2], scores_eig_by_region[2])
names(set_centr) = c('deg', 'clo', 'bet', 'eig')

set_centr_scaled = scale(set_centr[1:4])

# NbCluster를 이용한 최적의 군집갯수 찾기
set.seed(123)
NbClust(set_centr_scaled, min.nc=2, max.nc=10, index="alllong", method="kmeans")

# factoextra 패키지를 활용한 군집 찾기 
# WSS 방법
fviz_nbclust(set_centr_scaled, kmeans, method = "wss")
# Silouette 방법
fviz_nbclust(set_centr_scaled, kmeans, method = "silhouette")

# 결과요약
# 시드값: 123
# 클러스터링의 갯수를 결정하는 방법에는 군집내 차이를 줄이는 WWS, Silouette값이 1에 가장 가까운 클러스터 갯수를 선택하는 등 다양한 방법이 있다. 
# NbCluster 패키지는 이 외에도 다양한 clustering validity 지표의 계산 결과를 보여준다. 지표에 따라 다양한 최적 클러스터 값을 제시하고 있는데, 군집개수로서 2개가 적정하다고 주장하는 지표가 16개로서 제일 많기 때문에 다수결의 원칙에 따라 클러스터 수를 2개로 결정하게 되었다. 
# fviz_nbclust를 이용한 분석에서도 군집 개수가 1개에서 2개로 늘어날 때 집단 내 차이가 크게 감소하고 이후부터는 차이가 크지 않고, Siloutett값의 경우도 군집 갯수 2에서 약 0.6정도로 1에 제일 가까운 수치를 보여, NbClust의 결과와 일치한다.

set.seed(123)
km_centr = kmeans(set_centr_scaled, 2, nstart = 25)
km_centr

### 2. 위의 과정을 통해 도출된 군집분석 결과를 그래프로 시각화

fviz_cluster(km_centr, data = set_centr_scaled,
             elipse.type = "convex",
             palatte = "jco",
             repel = TRUE,
             ggtheme = theme_minimal())

# 지역별 코드명
for (i in 1:39) {
  print(paste(toString(i), ": ", nodes$region_name[i]))
}
