-- Modelo relacional proposto para a versão multiusuário (PostgreSQL / Supabase).
-- NÃO executar em produção sem configurar autenticação, RLS, políticas e testes.
create extension if not exists pgcrypto;
create table farms (id uuid primary key default gen_random_uuid(), name text not null, created_at timestamptz not null default now());
create table farm_members (farm_id uuid not null references farms(id), user_id uuid not null references auth.users(id), role text not null check(role in ('owner','manager','operator','viewer')), primary key(farm_id,user_id));
create table plots (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), name text not null, crop text not null, variety text, area_ha numeric(14,4) not null check(area_ha>0), plant_count integer check(plant_count>=0), planting_date date, active boolean not null default true, unique(farm_id,name));
create table seasons (id uuid primary key default gen_random_uuid(), plot_id uuid not null references plots(id), label text not null, start_date date, end_date date, status text not null default 'open' check(status in ('open','closed')), unique(plot_id,label));
create table suppliers (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), name text not null, document_number text);
create table products (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), name text not null, category text not null, base_unit text not null check(base_unit in ('ml','g','un')), active boolean not null default true);
create table purchases (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), supplier_id uuid references suppliers(id), purchase_date date not null, invoice_number text, total_amount numeric(16,2) not null check(total_amount>=0));
create table inventory_lots (id uuid primary key default gen_random_uuid(), purchase_id uuid not null references purchases(id), product_id uuid not null references products(id), batch_number text, expiry_date date, purchased_qty numeric(18,5) not null check(purchased_qty>0), unit_cost numeric(18,8) not null check(unit_cost>=0), unique(id,product_id));
create table operations (id uuid primary key default gen_random_uuid(), season_id uuid not null references seasons(id), operation_date date not null, operation_type text not null, description text, operator_name text, equipment_name text, weather jsonb, area_treated_ha numeric(14,4) check(area_treated_ha>0));
create table operation_consumptions (id uuid primary key default gen_random_uuid(), operation_id uuid not null references operations(id), lot_id uuid not null references inventory_lots(id), quantity numeric(18,5) not null check(quantity>0), unit_cost_snapshot numeric(18,8) not null check(unit_cost_snapshot>=0));
create table operation_costs (id uuid primary key default gen_random_uuid(), operation_id uuid not null references operations(id), category text not null, description text, amount numeric(16,2) not null check(amount>=0));
create table harvests (id uuid primary key default gen_random_uuid(), season_id uuid not null references seasons(id), harvest_date date not null, quantity_kg numeric(18,3) not null check(quantity_kg>0), quality_grade text, notes text);
create table customers (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), name text not null);
create table sales (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), customer_id uuid references customers(id), sale_date date not null, status text not null default 'invoiced' check(status in ('draft','invoiced','cancelled')), notes text);
create table sale_items (id uuid primary key default gen_random_uuid(), sale_id uuid not null references sales(id), season_id uuid not null references seasons(id), quantity_kg numeric(18,3) not null check(quantity_kg>0), price_per_kg numeric(16,4) not null check(price_per_kg>=0), discounts numeric(16,2) not null default 0 check(discounts>=0));
create table payments (id uuid primary key default gen_random_uuid(), sale_id uuid not null references sales(id), payment_date date not null, amount numeric(16,2) not null check(amount>0), method text);
create table expenses (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), season_id uuid references seasons(id), expense_date date not null, category text not null, description text not null, amount numeric(16,2) not null check(amount>=0), paid_at date);
create table equipment (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), name text not null, purchase_cost numeric(16,2), useful_life_years numeric(8,2));
create table equipment_usage (id uuid primary key default gen_random_uuid(), equipment_id uuid not null references equipment(id), operation_id uuid not null references operations(id), hours numeric(12,2) check(hours>=0), fuel_liters numeric(12,3) check(fuel_liters>=0), allocated_cost numeric(16,2) not null default 0 check(allocated_cost>=0));
create table cost_allocations (id uuid primary key default gen_random_uuid(), expense_id uuid not null references expenses(id), season_id uuid not null references seasons(id), amount numeric(16,2) not null check(amount>=0));
-- REQUISITOS PARA A PRÓXIMA FASE:
-- 1. Habilitar RLS em TODAS as tabelas antes de disponibilizar API pública.
-- 2. Políticas baseadas em farm_members, inclusive para joins indiretos.
-- 3. Transações/RPC com bloqueio de lote para impedir estoque negativo em acessos simultâneos.
-- 4. Validar pertença de área, safra, estoque, compras e vendas à mesma propriedade.
-- 5. Validar vendas <= colheitas disponíveis, considerando perdas e devoluções.
-- 6. Definir rateio de custos indiretos e método de custeio (lote/FIFO/médio).
-- 7. Auditoria de alterações, estornos, backups e conciliação financeira.

-- v0.5: mão de obra reutilizável por propriedade e alocação por safra
create table labor_rates (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), name text not null, hourly_rate numeric(16,4) not null check(hourly_rate>=0));
create table operation_labor (id uuid primary key default gen_random_uuid(), operation_id uuid not null references operations(id), labor_rate_id uuid not null references labor_rates(id), hours numeric(12,3) not null check(hours>0), hourly_rate_snapshot numeric(16,4) not null check(hourly_rate_snapshot>=0));
-- Para aplicações compartilhadas entre safras, separar evento operacional e alocações:
create table shared_operations (id uuid primary key default gen_random_uuid(), farm_id uuid not null references farms(id), operation_date date not null, kind text not null, notes text);
create table shared_operation_allocations (id uuid primary key default gen_random_uuid(), shared_operation_id uuid not null references shared_operations(id), season_id uuid not null references seasons(id), allocated_cost numeric(16,2) not null check(allocated_cost>=0));
