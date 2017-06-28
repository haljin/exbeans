defmodule Beans do
  require BeanMaker
  import BeanMaker
  @moduledoc false
  @type bean :: %Beans.GreenBean{} | %Beans.CoffeeBean{} | %Beans.BlueBean{} | %Beans.WaxBean{} | %Beans.BlackEyedBean{}


 defprotocol Bean do
   def harvest(bean, beanList)
 end


 defbean GreenBean, 3, 5, 6, 7
 defbean CoffeeBean, 4,7, 10, 12
 defbean BlueBean, 4, 6, 8, 10
 defbean WaxBean, 4, 7, 9, 11
 defbean BlackEyedBean, 2, 4, 5, 6
end


