defmodule Beans do
  require BeanMaker
  import BeanMaker
  @moduledoc false
  @type bean :: %Beans.GreenBean{} | %Beans.CoffeeBean{} | %Beans.BlueBean{} | %Beans.WaxBean{} | %Beans.BlackEyedBean{}


 defprotocol Bean do
   def harvest(bean, beanList)
   def count(bean)
 end


 defbean GreenBean, count: 14, levels: [3, 5, 6, 7]
 defbean CoffeeBean, count: 24, levels: [4,7, 10, 12]
 defbean BlueBean, count: 20, levels: [4, 6, 8, 10]
 defbean WaxBean, count: 22, levels: [4, 7, 9, 11]
 defbean BlackEyedBean, count: 10, levels: [2, 4, 5, 6]
end


