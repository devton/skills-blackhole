# Bowling Alley Framework — Onboarding que Converte

> Capítulo 13 | Product-Led Growth — Wes Bush

## Goal
Guiar usuários do signup até o primeiro outcome significativo (e depois até paid) sem salesy messaging.

## Analogia
Bowling: calhas (gutters) = abandono. Bumpers = mecanismos que impedem o usuário de sair da trilha.

---

## 3 Componentes

```
1. Straight Line (menor caminho signup → outcome)
2. Product Bumpers (dentro do produto)
3. Conversational Bumpers (fora do produto)
```

---

## 1. Straight Line

**Passo 1: Map Out the Path**
- Faça o signup completo do zero, screenshot de cada step (incluindo cliques em "OK")
- Mais de 30% dos steps obrigatórios de onboarding são desnecessários

**Passo 2: Label Every Step**
- 🟢 **Verde** = absolutamente necessário (upload de JS, email para conta)
- 🟡 **Amarelo** = feature avançada que pode vir depois
- 🔴 **Vermelho** = pode ser removido (cor de perfil, apelido da conta)

**Passo 3: Develop Straight Line**
- Remova vermelhos completamente
- Adie amarelos para após o primeiro outcome
- Resultado: "sequência de semáforos verdes" até o valor

> **Case:** Snappa removeu step de ativação de email → 27% a mais completando signup → +20% MRR

> **Case:** Canva detecta intent ("how to make a poster") e catapulta direto ao editor de posters em < 1 minuto

Template: `../templates/straight-line-audit.md`

---

## 2. Product Bumpers

### A. Welcome Messages
- Receba o usuário como um host (amigos dizem olá)
- Reafirme value proposition + construa suspense sobre o valor que vem
- Mostre o CEO/founder: humaniza e aumenta confiança

### B. Product Tours
- Só os green steps mais críticos (3–5 steps no máximo)
- "Focus mode": esconde nav e distrações (Hick's Law + Paradox of Choice)
- Para multi-produto: pergunta inicial catapulta para a track certa

### C. Progress Bars
- Humanos são viciados em progresso
- Comece com parte já preenchida (Endowed Progress Effect)
- Objetivos precisam parecer alcançáveis (42km soa pior que 9 × 5km)

### D. Onboarding Checklists
- 3–5 items para novos usuários
- Comece parcialmente preenchido (Endowed Progress Effect)
- Zeigarnik Effect: tarefa incompleta fica na memória = usuario volta para completar

### E. Onboarding Tooltips
- Ensina HOW TO (não só aponta botões)
- **Tooltip abuse**: tour de features sem levar a valor = evite
- Usos válidos: como usar, coaching, mostrar áreas novas para retentão

### F. Empty States
- Primeira vez que usuário vê o dashboard (sem dados)
- Mostre EXATAMENTE o que precisa ser feito para experienciar valor
- Ex: Buffer = "Conecte suas redes sociais" (sem isso o produto não funciona)
- Perguntas para definir:
  1. Que steps levam a quick win?
  2. Qual é o step mais crítico da straight line?
  3. Como garantir que a maioria complete?

---

## 3. Conversational Bumpers

### Smart Signals para Trigger
1. **Signup** → Track 1 (Quick Win)
2. **Quick Win** → Track 2 (Desired Outcome)
3. **Desired Outcome** → Track 3 (Convert)
4. **Customer** → remove das tracks de upgrade + Customer Welcome

### Track 1: Quick Win
- Emails: Welcome + Usage Tips
- NÃO tente vender
- Foco 100%: usuário experiencia quick win

### Track 2: Desired Outcome
- Emails: Usage Tips focados no outcome + Better Life
- Foco: usuário alcança desired outcome

### Track 3: Convert
- Emails: Sales Touch + Case Study + Expiry Warning + Trial Extension + Post-Trial Survey
- Trigger-based: ao upgradar, remove automaticamente → Customer Welcome
- LTV alto = mais outreach direto justificado

**Regra:** Conversational bumpers são training wheels. Se produto é bom, usuários voltam sozinhos.

---

## Referências
- Email templates: `email-sequences.md`
- Auditoria de onboarding: `../templates/straight-line-audit.md`
- Triple A Sprint: `triple-a-sprint.md`
