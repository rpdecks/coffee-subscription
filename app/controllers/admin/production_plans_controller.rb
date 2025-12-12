class Admin::ProductionPlansController < Admin::BaseController
  def show
    @plan = ProductionPlanService.call
  end
end
