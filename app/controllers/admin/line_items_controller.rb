class Admin::LineItemsController < Admin::BaseController
  resource_controller
  belongs_to :order
  ssl_required
  actions :all, :except => :index


  #override r_c create action as we want to use order#add_variant instead of creating line_item
  def create
    load_object
    variant = Variant.find(params[:line_item][:variant_id])

    before :create

    @order.add_variant(variant, params[:line_item][:quantity].to_i)

    if @order.save
      after :create
      set_flash :create
      response_for :create
    else
      after :create_fails
      set_flash :create_fails
      response_for :create_fails
    end

  end

  destroy.success.wants.html { render :partial => "admin/orders/form", :locals => {:order => @order}, :layout => false }

  new_action.response do |wants|
    wants.html {render :action => :new, :layout => false}
  end

  create.response do |wants|
    wants.html { render :partial => "admin/orders/form", :locals => {:order => @order}, :layout => false}
  end

  update.response do |wants|
    wants.html { render :partial => "admin/orders/form", :locals => {:order => @order}, :layout => false}
  end

  destroy.after :recalulate_totals
  update.after :recalulate_totals
  create.after :recalulate_totals

  private
  def recalulate_totals
    unless @order.shipping_method.nil?
      @order.shipping_charges.each do |shipping_charge|
        shipping_charge.update_attributes(:amount => @order.shipping_method.calculate_cost(@order.shipment))
      end
    end

    @order.tax_charges.each do |tax_charge|
      tax_charge.update_attributes(:amount => tax_charge.calculate_tax_charge)
    end

    @order.update_totals(true)
    @order.save

  end
end
