class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def policy_for(other_record)
    policy_class = [other_record.class.name, "Policy"].join.constantize
    policy_class.new(user, other_record)
  end

  def self.delegate_to(record_method)
    [:index?, :show?, :create?, :new?, :update?, :edit?, :destroy?].each do |method|
      define_method(method) do
        policy_for(record.send(record_method)).send("#{method}")
      end
    end
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
